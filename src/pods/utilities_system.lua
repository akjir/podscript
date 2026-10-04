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
---@param full_path string
---@return boolean
function system.directory_exists(full_path)
    if type(full_path) ~= "string" then error("Expected string for full_path, got " .. type(full_path), 2) end
    local safe_path = "'" .. full_path:gsub("'", "'\\''") .. "'"
    local success = os.execute("test -d " .. safe_path)
    return success == true or success == 0
end

---Get the absolute path of a given path.
---@param full_path string
---@return string
function system.get_absolute_path(full_path)
    if type(full_path) ~= "string" then error("Expected string for full_path, got " .. type(full_path), 2) end
    if string.is_nil_or_empty(full_path) then return "" end
    local safe_path = "'" .. full_path:gsub("'", "'\\''") .. "'"
    local handle = io.popen("realpath -m " .. safe_path .. " 2>/dev/null")
    if not handle then return full_path end
    local result = handle:read("*a")
    handle:close()
    if result and not string.is_nil_or_empty(string.trim(result)) then
        return string.trim(result)
    end
    return full_path
end

---Execute a command.
---Only executes a command, if simulate is set to false.
---@param command string
---@param prefix string
---@param simulate boolean
---@param direct boolean
function system.exec(command, prefix, simulate, direct)
    if type(command) ~= "string" then error("Expected string for command, got " .. type(command), 2) end
    if not string.ends_with(command, ";") then
        command = command .. ";"
    end

    if simulate then
        if type(prefix) == "string" and not string.is_nil_or_empty(prefix) then
            log.print(prefix)
        end
        log.print(command)
        return
    end

    log.debug("Execute: " .. command)

    if direct then
        local success, _, exit_code = os.execute("( " .. command .. " ) 2>/dev/null")
        if not success then
            log.error("Command exited with code '" .. tostring(exit_code) .. "'!")
        end
        return
    end

    -- combine STDOUT and STDERR using 2>&1
    local handle = io.popen("( " .. command .. " ) 2>&1")
    if not handle then
        log.error("Failed to execute command '" .. command .. "'!")
        return
    end

    local safe_prefix = ""
    if type(prefix) == "string" and not string.is_nil_or_empty(prefix) then
        safe_prefix = prefix
    end

    local output_captured = false
    for line in handle:lines() do
        if not output_captured then
            log.print(safe_prefix .. line)
            output_captured = true
        else
            log.print(line)
        end
    end

    if not output_captured then
        log.print(safe_prefix .. "...")
    end

    local success, _, exit_code = handle:close()

    -- check if the command actually succeeded
    if not success then
        log.error("Command exited with code '" .. tostring(exit_code) .. "'!")
    end
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
---@param full_path string
---@return boolean
function system.file_exists(full_path)
    if type(full_path) ~= "string" then error("Expected string for full_path, got " .. type(full_path), 2) end
    local file = io.open(full_path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

---List files in a directory matching a pattern.
---@param full_path string
---@param pattern string|nil
---@return table|nil files The list of filenames.
function system.list_directory(full_path, pattern)
    if type(full_path) ~= "string" then error("Expected string for full_path, got " .. type(full_path), 2) end
    if pattern ~= nil and type(pattern) ~= "string" then error("Expected string or nil for pattern, got " .. type(pattern), 2) end
    if not system.directory_exists(full_path) then return nil end
    local safe_path = "'" .. full_path:gsub("'", "'\\''") .. "'"
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
---@param full_path string
---@return table|nil result The object returned by the file (usually a table).
---@return string|nil error Error message if something went wrong.
---@return string|nil error_type The type of error ("load" or "execution").
function system.load_lua_file(full_path)
    if type(full_path) ~= "string" then error("Expected string for full_path, got " .. type(full_path), 2) end
    local chunk, err = loadfile(full_path)
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
---@param full_path string
---@return table|nil
function system.read_file_content_by_line(full_path)
    if type(full_path) ~= "string" then error("Expected string for full_path, got " .. type(full_path), 2) end
    local file = io.open(full_path, "r")
    if not file then
        log.error("Could not open file '" .. full_path .. "'!")
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
---@param full_path string
---@param content string
---@return boolean
function system.write_file(full_path, content)
    if type(full_path) ~= "string" then error("Expected string for full_path, got " .. type(full_path), 2) end
    if type(content) ~= "string" then error("Expected string for content, got " .. type(content), 2) end
    local file = io.open(full_path, "w")
    if not file then
        log.error("Could not write to file '" .. full_path .. "'!")
        return false
    end
    file:write(content)
    file:close()
    return true
end
