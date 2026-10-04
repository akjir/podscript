--[[

PodScript
Copyright (C) 2026  Stefan Stark

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <https://www.gnu.org/licenses/>.

--]]
---@diagnostic disable: duplicate-set-field

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION System
--
-- ------------------------------------------------------------------------- --

global system <const> = {}

---Check if the current Lua version is 5.5 or higher.
---@return boolean
function system.check_lua_version()
    local major_string, minor_string = _VERSION:match("Lua (%d+)%.(%d+)")
    if not major_string or not minor_string then return false end
    local major = tonumber(major_string)
    local minor = tonumber(minor_string)
    return major > 5 or (major == 5 and minor >= 5)
end

---Check if the current operating system is Linux.
---@return boolean
function system.check_os()
    local handle = io.popen("uname -s")
    if not handle then return false end
    local result = handle:read("*a")
    handle:close()

    -- we need to trim the result, because uname -s returns a newline
    return "Linux" == string.trim(result)
end

---Check if the current Podman version is 5.8.0 or higher.
---@return boolean
function system.check_podman_version()
    local handle = io.popen("podman --version 2>&1")
    if not handle then return false end
    local result = handle:read("*a")
    handle:close()

    -- podman --version returns something like "podman version 5.8.1"
    local major_string, minor_string = result:match("version%s*(%d+)%.(%d+)%.%d+")
    if not major_string or not minor_string then return false end
    local major = tonumber(major_string)
    local minor = tonumber(minor_string)
    return major > 5 or (major == 5 and minor >= 8)
end

---Check if a directory exists.
---@param path string
---@return boolean
function system.directory_exists(path)
    if type(path) ~= "string" then error("Expected string for path, got " .. type(path), 2) end
    local safe_path = "'" .. path:gsub("'", "'\\''") .. "'"
    local success = system.exec("test -d " .. safe_path, { interactive = true, silent = true })
    return success == true
end

---Check if a container exists and is running.
---@param container_name string
---@return boolean
function system.container_exists(container_name)
    if type(container_name) ~= "string" then error("Expected string for container_name, got " .. type(container_name), 2) end
    local escaped_name = string.escape_shell(container_name)
    local command = "podman container inspect -f '{{.State.Status}}' " .. escaped_name .. " 2>/dev/null"
    local lines = system.exec_capture(command)
    if lines and #lines > 0 and lines[1] == "running" then
        return true
    end
    return false
end

---Get the absolute path of a given path.
---@param path string
---@return string
function system.get_absolute_path(path)
    if type(path) ~= "string" then error("Expected string for path, got " .. type(path), 2) end
    if string.is_nil_or_empty(path) then return "" end
    local safe_path = "'" .. path:gsub("'", "'\\''") .. "'"
    local handle = io.popen("realpath -m " .. safe_path .. " 2>/dev/null")
    if not handle then return path end
    local result = handle:read("*a")
    handle:close()
    if result then
        local trimmed_result = string.trim(result)
        if not string.is_nil_or_empty(trimmed_result) then
            return trimmed_result
        end
    end
    return path
end

---Execute a command.
---@param command string
---@param options table|nil Options for execution.
---@return boolean success, string|nil exit_reason, number|nil exit_code
function system.exec(command, options)
    if type(command) ~= "string" then error("Expected string for command, got " .. type(command), 2) end
    options = options or {}
    if type(options) ~= "table" then error("Expected table for options, got " .. type(options), 2) end

    local prefix = options.prefix or ""
    local simulate = options.simulate == true
    local interactive = options.interactive == true
    local silent = options.silent == true

    local final_command = command
    local print_command = command
    if not string.ends_with(print_command, ";") then
        print_command = print_command .. ";"
    end

    if not interactive then
        final_command = print_command
    end

    if simulate then
        if not string.is_nil_or_empty(prefix) then
            log.print(prefix)
        end
        log.print(print_command)
        return true, "exit", 0
    end

    log.debug("Execute: " .. print_command)

    if interactive then
        local success, exit_reason, exit_code = os.execute(final_command)
        if not success and not silent then
            log.error("Command exited with code '" .. tostring(exit_code) .. "'!")
        end
        return success, exit_reason, exit_code
    end

    -- combine STDOUT and STDERR using 2>&1
    local handle = io.popen("( " .. final_command .. " ) 2>&1")
    if not handle then
        if not silent then
            log.error("Failed to execute command '" .. final_command .. "'!")
        end
        return false, "failed", -1
    end

    local output_captured = false
    for line in handle:lines() do
        if not output_captured then
            log.print(prefix .. line)
            output_captured = true
        else
            log.print(line)
        end
    end

    if not output_captured then
        log.print(prefix .. "...")
    end

    local success, exit_reason, exit_code = handle:close()

    -- check if the command actually succeeded
    if not success and not silent then
        log.error("Command exited with code '" .. tostring(exit_code) .. "'!")
    end

    return success, exit_reason, exit_code
end

---Execute a command and capture its standard output as a list of lines.
---@param command string
---@return table|nil lines The lines captured from STDOUT, or nil if execution failed.
function system.exec_capture(command)
    if type(command) ~= "string" then error("Expected string for command, got " .. type(command), 2) end
    local handle = io.popen(command)
    if not handle then return nil end

    local lines = {}
    for line in handle:lines() do
        lines[#lines + 1] = line
    end
    handle:close()
    return lines
end

---Check if a file exists.
---@param path string
---@return boolean
function system.file_exists(path)
    if type(path) ~= "string" then error("Expected string for path, got " .. type(path), 2) end
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

---List files in a directory matching a pattern.
---@param path string
---@param pattern string|nil
---@return table|nil files The list of filenames.
function system.list_directory(path, pattern)
    if type(path) ~= "string" then error("Expected string for path, got " .. type(path), 2) end
    if pattern ~= nil and type(pattern) ~= "string" then error("Expected string or nil for pattern, got " .. type(pattern), 2) end
    if not system.directory_exists(path) then return nil end
    local safe_path = "'" .. path:gsub("'", "'\\''") .. "'"
    local handle = io.popen("ls -1 " .. safe_path .. " 2>/dev/null")
    if not handle then return nil end
    local files = {}
    for line in handle:lines() do
        if not pattern or string.match(line, pattern) then
            files[#files + 1] = line
        end
    end
    handle:close()
    return files
end

---Loads a Lua file and returns the result.
---@param path string
---@return table|nil result The object returned by the file (usually a table).
---@return string|nil error Error message if something went wrong.
---@return string|nil error_type The type of error ("load" or "execution").
function system.load_lua_file(path)
    if type(path) ~= "string" then error("Expected string for path, got " .. type(path), 2) end
    local chunk, err = loadfile(path)
    if not chunk then
        return nil, err, "load"
    end
    local success, result = pcall(chunk)
    if not success then
        return nil, result, "execution"
    end
    return result, nil, nil
end

---Read file content line by line and return as a table.
---@param path string
---@return table|nil
function system.read_file_content_by_line(path)
    if type(path) ~= "string" then error("Expected string for path, got " .. type(path), 2) end
    local file = io.open(path, "r")
    if not file then
        log.error("Could not open file '" .. path .. "'!")
        return nil
    end
    local lines = {}
    for line in file:lines() do
        lines[#lines + 1] = line
    end
    file:close()
    return lines
end

---Check if the program is run with elevated execution rights (sudo).
---@return boolean
function system.runs_elevated()
    local handle = io.popen("id -u")
    if not handle then return false end
    local result = handle:read("*a")
    handle:close()
    return "0" == string.trim(result)
end

---Write content to a file.
---@param path string
---@param content string
---@return boolean
function system.write_file(path, content)
    if type(path) ~= "string" then error("Expected string for path, got " .. type(path), 2) end
    if type(content) ~= "string" then error("Expected string for content, got " .. type(content), 2) end
    local file = io.open(path, "w")
    if not file then
        log.error("Could not write to file '" .. path .. "'!")
        return false
    end
    file:write(content)
    file:close()
    return true
end
