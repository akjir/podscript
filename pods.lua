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

global<const> *

-- ------------------------------------------------------------------------- --
--
--
--       PODSCRIPT
--
--
-- ------------------------------------------------------------------------- --

local VERSION <const> = "1.5.0"
local BUILD <const> = "247.5f2a7ef.dev"

---Constructs and returns the full PodScript version string formatted as 'v<VERSION>+<BUILD>'.
---@return string The formatted version string.
local function get_version_string()
    return "v" .. VERSION .. "+" .. BUILD
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Log
--
-- ------------------------------------------------------------------------- --

global log<const> = {
    -- Debug flag to enable verbose logging
    debug_enabled = false,

    -- Proxy to handle output, defaults to standard print
    print = print,
}

---Outputs a debug-level message if verbose logging is enabled.
---@param ... any The variable arguments to format and print.
function log.debug(... args)
    if log.debug_enabled then
        log.print("DEBUG: " .. log.format_args(...))
    end
end

---Outputs an error-level message.
---@param ... any The variable arguments to format and print.
function log.error(... args)
    log.print("ERROR: " .. log.format_args(...))
end

---Formats variable arguments into a single string separated by spaces.
---@param ... any The variable arguments to format.
---@return string The formatted string.
function log.format_args(... args)
    local count = args.n
    if count == 0 then
        return ""
    elseif count == 1 then
        return tostring(args[1])
    end

    local parts = table.create(count)
    for i = 1, count do
        parts[i] = tostring(args[i])
    end
    return table.concat(parts, " ")
end

---Outputs an info-level message.
---@param ... any The variable arguments to format and print.
function log.info(... args)
    log.print("INFO: " .. log.format_args(...))
end

---Outputs a warning-level message.
---@param ... any The variable arguments to format and print.
function log.warning(... args)
    log.print("WARNING: " .. log.format_args(...))
end
-- ------------------------------------------------------------------------- --
--
--    SECTION String
--
-- ------------------------------------------------------------------------- --

---Evaluates whether a string starts with a specified prefix.
---@param str string The source string to evaluate.
---@param prefix string The prefix to search for.
---@return boolean True if the string starts with the prefix, false otherwise.
function string.begins_with(str, prefix)
    return str:sub(1, #prefix) == prefix
end

---Evaluates whether a string ends with a specified suffix.
---@param str string The source string to evaluate.
---@param suffix string The suffix to search for.
---@return boolean True if the string ends with the suffix, false otherwise.
function string.ends_with(str, suffix)
    return str:sub(- #suffix) == suffix
end

---Escapes a string securely for injection into shell commands.
---@param str string|nil The string to escape.
---@param always_quote boolean|nil True to wrap the string in single quotes unconditionally.
---@return string The safely escaped shell string.
function string.escape_shell(str, always_quote)
    if str == nil then
        return "''"
    end
    str = tostring(str)
    if always_quote or str == "" or str:find("[^%w_%-./:=@]") then
        return "'" .. str:gsub("'", "'\\''") .. "'"
    end
    return str
end

---Evaluates whether a string is nil or strictly empty.
---@param str string|nil The string to evaluate.
---@return boolean True if the string is nil or empty, false otherwise.
function string.is_nil_or_empty(str)
    return str == nil or str == ""
end

---Strips leading and trailing whitespace characters from a string.
---@param str string|nil The string to trim.
---@return string The trimmed string, or an empty string if nil.
function string.trim(str)
    if str == nil then return "" end
    -- avoid lazy evaluation of '.-' in str:match("^%s*(.-)%s*$")
    return str:match("^()%s*$") and "" or str:match("^%s*(.*%S)")
end

---Partitions a string into a table of substrings divided by a given separator.
---@param str string The string to partition.
---@param sep string The separator substring.
---@return table An array of resulting substrings.
function string.split(str, sep)
    if sep == nil or sep == "" then
        return {str}
    end
    local result = {}
    local last_end = 1
    local s, e = str:find(sep, 1, true)
    while s do
        result[#result + 1] = str:sub(last_end, s - 1)
        last_end = e + 1
        s, e = str:find(sep, last_end, true)
    end
    result[#result + 1] = str:sub(last_end)
    return result
end

---Computes the visible character count of a string, accounting for multi-byte UTF-8 sequences.
---@param str string The string to measure.
---@return integer The visible character length.
function string.visible_length(str)
    if str == nil then return 0 end
    local extra = 0
    for i = 1, #str do
        local b = str:byte(i)
        if b >= 0x80 and b <= 0xBF then
            extra = extra + 1
        end
    end
    return #str - extra
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Table
--
-- ------------------------------------------------------------------------- --

---Appends elements from one or more sequential tables into a target table.
---@param target table|nil The destination table.
---@param ... table|nil The source tables to append.
function table.append(target, ...sources)
    if target == nil then return end
    for i = 1, sources.n do
        local source = sources[i]
        if source ~= nil then
            table.move(source, 1, #source, #target + 1, target)
        end
    end
end

---Evaluates whether a sequential table contains a specific value.
---@param target table|nil The table to search.
---@param value any The value to locate.
---@return boolean True if the value is found, false otherwise.
function table.contains(target, value)
    if target == nil then return false end
    for i = 1, #target do
        if (target[i] == value) then return true end
    end
    return false
end

---Retrieves a value from a table by key, returning a fallback if missing.
---@param target table The table to query.
---@param key any The key to lookup.
---@param default any The fallback value.
---@return any The resolved value.
function table.get_or_default(target, key, default)
    if target == nil then return default end
    local value = target[key]
    if value ~= nil then
        return value
    end
    return default
end

---Evaluates whether a table contains a specific key.
---@param target table The table to inspect.
---@param key any The key to locate.
---@return boolean True if the key exists, false otherwise.
function table.has_key(target, key)
    return target ~= nil and target[key] ~= nil
end

---Evaluates whether a table is nil or contains no elements.
---@param target table The table to inspect.
---@return boolean True if nil or empty, false otherwise.
function table.is_nil_or_empty(target)
    return target == nil or next(target) == nil
end

---Merges key-value pairs from multiple source tables into a target table, overwriting existing keys.
---@param target table The destination table.
---@param ... table The source tables.
---@return table The merged target table.
function table.merge(target, ...sources)
    if target == nil then return sources[1] end
    for i = 1, sources.n do
        local source = sources[i]
        if source ~= nil then
            for key, value in pairs(source) do
                target[key] = value
            end
        end
    end
    return target
end

---Creates a new sequential table containing only unique values from the source.
---@param target table The source table.
---@return table A new table free of duplicates.
function table.remove_duplicates(target)
    if type(target) ~= "table" then
        error("table.remove_duplicates expects a table as target, got " .. type(target), 2)
    end
    local count = #target
    if count == 0 then return {} end

    local seen = table.create(0, count) -- Keeps track of values we've already encountered
    local result = table.create(count)  -- The new table with unique values
    local index = 1                     -- Manual index tracker is faster than table.insert

    for i = 1, count do
        local value = target[i]
        -- If the value hasn't been added to 'seen' yet...
        if not seen[value] then
            seen[value] = true    -- Mark it as seen
            result[index] = value -- Add it to the result array
            index = index + 1     -- Increment the index
        end
    end

    return result
end

---Counts the total number of key-value pairs in a table, including non-numeric keys.
---@param table table The table to measure.
---@return integer The total element count.
function table.size(table)
    if table == nil then return 0 end
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
end

---Extracts a sub-sequence from a sequential table, utilizing 1-based indexing.
---@param target table The source table.
---@param i integer|nil The starting index (inclusive, defaults to 1).
---@param j integer|nil The ending index (inclusive, defaults to -1).
---@return table A new table containing the extracted slice.
function table.sub(target, i, j)
    if type(target) ~= "table" then
        error("table.sub expects a table as target, got " .. type(target), 2)
    end
    local len = #target

    i = i or 1
    j = j or -1

    if i < 0 then i = len + i + 1 end
    if j < 0 then j = len + j + 1 end

    i = math.max(1, i)
    j = math.min(len, j)

    if i > j then return {} end

    local count = j - i + 1
    return table.move(target, i, j, 1, table.create(count))
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Utilities
--
-- ------------------------------------------------------------------------- --

global util <const> = {}

---Constructs a complete file path from a base directory, filename, and extension.
---@param path string The base directory path.
---@param file_name string The name of the file.
---@param file_extension string The extension to append (e.g., '.lua').
---@return string The fully resolved file path.
function util.build_full_path(path, file_name, file_extension)
    if not string.begins_with(path, "/") and
        not string.begins_with(path, ".")
    then
        path = "./" .. path
    end
    if string.is_nil_or_empty(file_name) then
        if string.is_nil_or_empty(file_extension) then
            return path
        else
            return path .. file_extension
        end
    elseif string.ends_with(path, "/") or string.begins_with(file_name, "/") then
        return path .. file_name .. file_extension
    else
        return path .. "/" .. file_name .. file_extension
    end
end

---Formats a line by padding it with spaces until the target column is reached, then appending the status.
---@param line string The line content.
---@param status string The status to append.
---@param target_column integer|nil The target column for alignment (default: 44).
---@return string # The fully formatted line.
function util.format_line(line, status, target_column)
    local visible = string.visible_length(line)
    local pad = (target_column or 44) - visible
    if pad < 1 then pad = 1 end
    return line .. string.rep(" ", pad) .. status
end

---Normalizes a name by converting it to lowercase, trimming whitespace, and replacing internal spaces with underscores.
---@param str string The name to normalize.
---@return string # The normalized name.
function util.normalize_name(str)
    return string.lower(str:trim():gsub("%s+", "_"))
end

---Splits a string by the first equals sign. If no equals sign is found, the value is set to true (as flag is given).
---@param argument string The input string to be split.
---@return string, string|boolean # The key and value.
function util.split_argument(argument)
    local clean_argument = string.gsub(argument, "^%-+", "")
    local parameter, value = string.match(clean_argument, "^([^=]+)=(.*)$")
    if parameter then
        return parameter, value
    end
    return clean_argument, true
end

-- ------------------------------------------------------------------------- --
--
--    SECTION System
--
-- ------------------------------------------------------------------------- --

global system <const> = {}

---Evaluates whether the executing Lua runtime is version 5.5 or higher.
---@return boolean True if the version requirement is met, false otherwise.
function system.check_lua_version()
    local major_string, minor_string = _VERSION:match("Lua (%d+)%.(%d+)")
    if not major_string or not minor_string then return false end
    local major = tonumber(major_string)
    local minor = tonumber(minor_string)
    return major > 5 or (major == 5 and minor >= 5)
end

---Evaluates whether the host operating system is Linux via uname.
---@return boolean True if running on Linux, false otherwise.
function system.check_os()
    local handle = io.popen("uname -s")
    if not handle then return false end
    local result = handle:read("*a")
    handle:close()

    -- we need to trim the result, because uname -s returns a newline
    return "Linux" == string.trim(result)
end

---Evaluates whether the installed Podman CLI is version 5.8.0 or higher.
---@return boolean True if the version requirement is met, false otherwise.
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

---Evaluates whether a directory exists at the specified path.
---@param path string The directory path to verify.
---@return boolean True if the directory exists, false otherwise.
function system.directory_exists(path)
    if type(path) ~= "string" then error("Expected string for path, got " .. type(path), 2) end
    local safe_path = "'" .. path:gsub("'", "'\\''") .. "'"
    local success = system.exec("test -d " .. safe_path, { interactive = true, silent = true })
    return success == true
end

---Evaluates whether a specific Podman container is currently running.
---@param container_name string The name of the container to inspect.
---@return boolean True if the container is running, false otherwise.
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

---Resolves the absolute path for a given file system path using realpath.
---@param path string The path to resolve.
---@return string The absolute path.
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

---Executes a shell command synchronously, optionally buffering output or running interactively.
---@param command string The shell command to execute.
---@param options table|nil Configuration options (simulate, interactive, silent, prefix).
---@return boolean success True if the command exited with code 0.
---@return string|nil exit_reason The reason for termination (e.g., 'exit').
---@return number|nil exit_code The numeric exit status.
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
        success = (success == true) -- os.execute returns boolean?
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
    success = (success == true) -- handle:close returns boolean?

    -- check if the command actually succeeded
    if not success and not silent then
        log.error("Command exited with code '" .. tostring(exit_code) .. "'!")
    end

    return success, exit_reason, exit_code
end

---Executes a shell command and captures standard output into an array of lines.
---@param command string The shell command to execute.
---@return table|nil lines An array of output lines, or nil if execution failed.
---@return boolean success True if the command exited cleanly.
function system.exec_capture(command)
    if type(command) ~= "string" then error("Expected string for command, got " .. type(command), 2) end

    -- Redirect STDERR to /dev/null to prevent console bleeding
    local handle = io.popen("( " .. command .. " ) 2>/dev/null")
    if not handle then return nil, false end

    local lines = {}
    for line in handle:lines() do
        lines[#lines + 1] = line
    end

    local success = handle:close()
    return lines, (success == true)
end

---Evaluates whether a file exists and is readable at the specified path.
---@param path string The file path to verify.
---@return boolean True if the file is readable, false otherwise.
function system.file_exists(path)
    if type(path) ~= "string" then error("Expected string for path, got " .. type(path), 2) end
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

---Retrieves a list of files within a directory, optionally filtered by a Lua pattern.
---@param path string The directory to scan.
---@param pattern string|nil A Lua pattern to filter filenames.
---@return table|nil An array of matching filenames, or nil if the directory is unreadable.
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

---Loads and executes a Lua script, capturing any compilation or runtime errors.
---@param path string The path to the Lua file.
---@return table|nil result The value returned by the executed chunk.
---@return string|nil error The error message, if any.
---@return string|nil error_type The error phase ('load' or 'execution').
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

---Reads a file and returns its contents as an array of lines.
---@param path string The path to the file.
---@return table|nil An array of lines, or nil if the file could not be opened.
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

---Evaluates whether the current process is running with root privileges (UID 0).
---@return boolean True if elevated, false otherwise.
function system.runs_elevated()
    local handle = io.popen("id -u")
    if not handle then return false end
    local result = handle:read("*a")
    handle:close()
    return "0" == string.trim(result)
end

---Writes string content to a file, overwriting any existing data.
---@param path string The destination file path.
---@param content string The data to write.
---@return boolean True upon successful write, false otherwise.
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
-- ------------------------------------------------------------------------- --
--
--    SECTION Container
--
-- ------------------------------------------------------------------------- --

---Creates and starts a container within a specified pod using Podman.
---@param container table Container configuration table.
---@param pod table Pod configuration table.
---@param simulate boolean True to simulate the creation command without executing it.
local function container__create(container, pod, simulate)
    if type(container) ~= "table" then error("container must be a table", 2) end
    if type(pod) ~= "table" then error("pod must be a table", 2) end
    -- main command
    local commands = table.create(16)
    commands[1] = "podman run"

    -- container name
    commands[#commands + 1] = "--name"
    commands[#commands + 1] = string.escape_shell(container.name)

    -- add container to pod
    commands[#commands + 1] = "--pod"
    commands[#commands + 1] = string.escape_shell(pod.name)

    -- detach
    -- default is true
    if container.detach ~= false then
        commands[#commands + 1] = "--detach"
    end

    -- container restart
    if not string.is_nil_or_empty(container.restart) then
        commands[#commands + 1] = "--restart"
        commands[#commands + 1] = container.restart
    end

    -- container volumes
    if not table.is_nil_or_empty(container.volumes) then
        for i = 1, #container.volumes do
            local host_dir = container.volumes[i][1]
            local container_dir = container.volumes[i][2]
            local options = container.volumes[i][3]
            if string.is_nil_or_empty(container_dir) then
                log.error("Container dir cannot be empty! (" .. container.name .. ")")
            else
                local command = ""
                if string.is_nil_or_empty(host_dir) then
                    command = container_dir
                else
                    if not string.begins_with(host_dir, "/") then
                        if string.begins_with(host_dir, "./") then
                            host_dir = string.sub(host_dir, 2)
                        end
                        host_dir = util.build_full_path(pod.path, host_dir, "")
                    end
                    command = host_dir .. ":" .. container_dir
                end
                if not string.is_nil_or_empty(options) then
                    command = command .. ":" .. options
                end
                commands[#commands + 1] = "--volume"
                commands[#commands + 1] = string.escape_shell(command)
            end
        end
    end

    -- container options
    -- if not supported by pods, add them directly to the podman run command
    if not table.is_nil_or_empty(container.options) then
        commands[#commands + 1] = table.concat(container.options, " ")
    end

    -- container image
    local registry = table.get_or_default(container, "registry", pod.registry)
    commands[#commands + 1] = string.escape_shell(registry .. "/" .. container.image)

    -- commands
    -- see: podman run --detach image:tag command
    if not table.is_nil_or_empty(container.commands) then
        for i = 1, #container.commands do
            commands[#commands + 1] = string.escape_shell(container.commands[i])
        end
    end

    -- create and execute final podman command
    system.exec(table.concat(commands, " "), {
        prefix = "Create container '" .. container.name .. "': ",
        simulate = simulate
    })
end

---Ensures a container has a valid name, generating one from the pod name and an alternate if omitted or prefixed with an asterisk.
---@param container table Container configuration table to update.
---@param pod_name string The name of the parent pod.
---@param container_alternate_name string A fallback name to append if the container name is missing.
---@return boolean True upon successful name resolution.
local function container__ensure_name(container, pod_name, container_alternate_name)
    if type(container) ~= "table" then error("container must be a table", 2) end
    -- container name is optional
    if string.is_nil_or_empty(container.name) then
        container.name = pod_name .. "-" .. container_alternate_name
    else
        container.name = util.normalize_name(container.name)
        if string.begins_with(container.name, "*") then
            container.name = pod_name .. "-" .. container.name:sub(2)
        end
    end
    return true
end

---Validates the configuration of a container, verifying required fields like the image.
---@param container table Container configuration table to validate.
---@param pod_name string The name of the parent pod.
---@return boolean True if the container is valid, false otherwise.
local function container__is_valid(container, pod_name)
    if type(container) ~= "table" then error("container must be a table", 2) end
    if table.is_nil_or_empty(container) then
        log.error("A container in pod '" .. pod_name .. "' is empty!")
        return false
    end
    -- test for container image
    if string.is_nil_or_empty(container.image) then
        log.error("Image not set for container '" .. container.name .. "'!")
        return false
    end
    return true
end

---Stops and removes a specified container via Podman.
---@param container table Container configuration table containing the container name.
---@param simulate boolean True to simulate the stop and remove commands without executing them.
local function container__remove(container, simulate)
    if type(container) ~= "table" then error("container must be a table", 2) end
    system.exec("podman stop " .. string.escape_shell(container.name), { prefix = "Stop container '" .. container.name .. "': ", simulate = simulate })
    system.exec("podman rm " .. string.escape_shell(container.name), { prefix = "Remove container '" .. container.name .. "': ", simulate = simulate })
end

---Pulls the latest image for a specified container from its registry using Podman.
---@param container table Container configuration table containing image details.
---@param pod table Pod configuration table used for fallback registry resolution.
---@param simulate boolean True to simulate the pull command without executing it.
local function container__update(container, pod, simulate)
    if type(container) ~= "table" then error("container must be a table", 2) end
    if type(pod) ~= "table" then error("pod must be a table", 2) end
    local registry = table.get_or_default(container, "registry", pod.registry)
    log.print("Update container '" .. container.name .. "' ...")
    system.exec("podman pull " .. string.escape_shell(registry .. "/" .. container.image), { simulate = simulate, interactive = true })
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Recipe
--
-- ------------------------------------------------------------------------- --

---Loads and evaluates a PodScript recipe file, returning the resulting configuration table.
---@param recipe_path string The base directory path containing the recipes.
---@param recipe_name string The specific name of the recipe to load.
---@param suppress_errors boolean|nil True to suppress error logging if the recipe fails to load.
---@return table|nil The loaded recipe table, or nil if an error occurred.
local function recipe__load(recipe_path, recipe_name, suppress_errors)
    local full_path = util.build_full_path(recipe_path, recipe_name, ".lua")
    local recipe, error, _ = system.load_lua_file(full_path)
    if recipe == nil then
        if not suppress_errors then
            if error ~= nil then
                log.error(error)
            end
            log.error("Couldn't load recipe '" .. full_path .. "'!")
        end
        return nil
    else
        return recipe
    end
end

---Validates a loaded recipe, ensuring all required fields, pod properties, and containers are properly configured.
---@param context table Application context providing default configuration values.
---@param recipe table The recipe table to validate and normalize.
---@param file_name string The name of the recipe file (used for error reporting).
---@return boolean True if the recipe is valid, false otherwise.
local function recipe__validate(context, recipe, file_name)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    local config = context.config or {}
    local pods = config.pods or {}
    -- test for pod config name
    if string.is_nil_or_empty(recipe.name) then
        log.error("No recipe name in recipe '" .. file_name .. "' set!")
        return false
    else
        recipe.name = string.trim(recipe.name)
    end

    -- test for pod section
    if table.is_nil_or_empty(recipe.pod) then
        log.error("Pod section in recipe '" .. file_name .. "' not defined! or empty")
        return false
    end

    -- test for pod name
    -- pod name is optional
    if string.is_nil_or_empty(recipe.pod.name) then
        recipe.pod.name = util.normalize_name(recipe.name)
    else
        recipe.pod.name = util.normalize_name(recipe.pod.name)
    end

    -- test for commands
    if table.is_nil_or_empty(recipe.pod.commands) then
        recipe.pod.commands = {}
    end

    -- test for pod registry
    if string.is_nil_or_empty(recipe.pod.registry) then
        log.error("No default registry in recipe '" .. file_name .. "' set or empty!")
        return false
    end

    -- test for valid pod path
    if string.is_nil_or_empty(recipe.pod.path) then
        -- if no pod path set in recipe use default path from config
        if string.is_nil_or_empty(pods.path) then
            log.error("No default pod path and pod path in recipe '" .. file_name .. "' set or empty!")
            return false
        else
            -- if pod path not set use default path with pod name as folder name
            local path = util.build_full_path(pods.path, recipe.pod.name, "")
            log.debug("No pod path in recipe '" .. file_name .. "' set. Path '" .. path .. "' used.")
            recipe.pod.path = path
        end
    end

    -- test for container section
    if table.is_nil_or_empty(recipe.containers) then
        log.error("Container section in recipe '" .. file_name .. "' not defined or empty!")
        return false
    end

    -- test if containers are valid
    local pod_name = recipe.pod.name
    for id = 1, #recipe.containers do
        if not container__is_valid(recipe.containers[id], pod_name) then
            return false
        end
    end
    return true
end

---Resolves a precise container name from a user specification (e.g., numeric index, exact name, or relative *name).
---@param recipe table The recipe containing the container definitions.
---@param container_spec string|number The container identifier to resolve.
---@return string|nil The resolved absolute container name, or nil if not found.
local function recipe__resolve_container_name(recipe, container_spec)
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    if type(container_spec) == "number" or tonumber(container_spec) then
        local container_index = tonumber(container_spec)
        if container_index and recipe.containers[container_index] then
            local container = recipe.containers[container_index]
            container__ensure_name(container, recipe.pod.name, tostring(container_index))
            return container.name
        end
    end

    local spec_str = tostring(container_spec)
    local container_name = util.normalize_name(spec_str)
    local alternate_container_name

    if string.begins_with(container_name, "*") then
        container_name = recipe.pod.name .. "-" .. container_name:sub(2)
    else
        alternate_container_name = recipe.pod.name .. "-" .. container_name
    end

    for i, container in ipairs(recipe.containers) do
        container__ensure_name(container, recipe.pod.name, tostring(i))
        if container.name == container_name then
            return container.name
        end
    end

    if alternate_container_name then
        for i, container in ipairs(recipe.containers) do
            container__ensure_name(container, recipe.pod.name, tostring(i))
            if container.name == alternate_container_name then
                return container.name
            end
        end
    end

    return nil
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Pod
--
-- ------------------------------------------------------------------------- --

---Constructs and executes Podman commands to create a pod and its defined containers.
---@param recipe table The recipe containing the pod and container configurations.
---@param simulate boolean True to simulate the creation commands without executing them.
local function pod__create(recipe, simulate)
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    local commands = table.create(8)
    commands[1] = "podman pod create"

    -- pod name
    commands[#commands + 1] = "--name"
    commands[#commands + 1] = string.escape_shell(recipe.pod.name)

    -- pod publish
    if not table.is_nil_or_empty(recipe.pod.publish) then
        local publish = recipe.pod.publish
        for _, entry in pairs(publish) do
            local size = table.size(entry)
            if size == 1 then
                commands[#commands + 1] = "--publish " .. entry[1]
            elseif size == 2 then
                local e1 = entry[1]
                local e2 = entry[2]
                if e1 == "" then
                    commands[#commands + 1] = "--publish " .. e2
                elseif e2 == "TCP" or e2 == "UDP" then
                    commands[#commands + 1] = "--publish " .. e1 .. "/" .. e2
                else
                    commands[#commands + 1] = "--publish " .. e1 .. ":" .. e2
                end
            elseif size > 2 then
                commands[#commands + 1] = "--publish " .. entry[1] .. ":" .. entry[2] .. "/" .. entry[3]
            end
        end
    end

    -- pod options
    -- if not supported by pods, add them directly to the podman run command
    if not table.is_nil_or_empty(recipe.pod.options) then
        commands[#commands + 1] = table.concat(recipe.pod.options, " ")
    end

    -- create pod
    system.exec(table.concat(commands, " "), {
        prefix = "Create pod '" .. recipe.name .. "' ('" .. recipe.pod.name .. "'): ",
        simulate = simulate
    })

    -- create containers
    local containers = recipe.containers
    for id = 1, #containers do
        local container = containers[id]
        container__ensure_name(container, recipe.pod.name, tostring(id))
        container__create(container, recipe.pod, simulate)
    end
end

---Stops and removes all containers associated with a pod, followed by the pod itself, via Podman.
---@param recipe table The recipe defining the pod and containers to remove.
---@param simulate boolean True to simulate the removal commands without executing them.
local function pod__remove(recipe, simulate)
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    -- remove containers
    local containers = recipe.containers
    for id = #containers, 1, -1 do -- reverse order when shutting down containers
        local container = containers[id]
        container__ensure_name(container, recipe.pod.name, tostring(id))
        container__remove(container, simulate)
    end

    -- remove pod
    system.exec("podman pod rm " .. string.escape_shell(recipe.pod.name), {
        prefix = "Remove pod '" .. recipe.name .. "' ('" .. recipe.pod.name .. "'): ",
        simulate = simulate
    })
end

---Removes an existing pod and its containers, then sequentially recreates them.
---@param recipe table The recipe defining the pod and containers to recreate.
---@param simulate boolean True to simulate the recreation commands without executing them.
local function pod__recreate(recipe, simulate)
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    pod__remove(recipe, simulate)
    pod__create(recipe, simulate)
end

---Iterates over a pod's containers and pulls their respective latest images from their registries.
---@param recipe table The recipe defining the pod and its containers.
---@param simulate boolean True to simulate the update commands without executing them.
local function pod__update(recipe, simulate)
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    log.print("Update pod '" .. recipe.name .. "' ('" .. recipe.pod.name .. "') ...")
    local containers = recipe.containers

    -- update containers
    for id = 1, #containers do
        local container = containers[id]
        container__ensure_name(container, recipe.pod.name, tostring(id))
        container__update(containers[id], recipe.pod, simulate)
    end
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Config
--
-- ------------------------------------------------------------------------- --

---Checks if a specific recipe is defined within the application configuration.
---@param context table Application context containing configuration data.
---@param recipe_name string Name of the recipe to search for.
---@return boolean True if the recipe exists in a group, false otherwise.
local function config__has_recipe(context, recipe_name)
    if type(context) ~= "table" then error("context must be a table", 2) end
    local groups = context.config.recipes.groups or {}

    for _, group_targets in pairs(groups) do
        if type(group_targets) == "table" then
            if table.contains(group_targets, recipe_name) then
                return true
            end
        end
    end
    return false
end

---Resolves group aliases and expands targets into a unique list of individual recipe names.
---@param context table Application context containing configuration data.
---@param list table List of target strings (recipe names or @group aliases).
---@return table|boolean A deduplicated array of recipe names, or false if an error occurred.
local function config__untangle(context, list)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if log.debug_enabled and not table.is_nil_or_empty(list) then
        log.debug("Targets   - " .. table.concat(list, " "))
    end

    local targets = list
    local groups = {}
    if context.config and context.config.recipes and context.config.recipes.groups then
        groups = context.config.recipes.groups
    end

    local untangled = {}

    for i = 1, #targets do
        local target = targets[i]

        -- 1. Handle group targeting (e.g., @group_name)
        if string.begins_with(target, "@") then

            if string.find(target, "/") or string.find(target, ":") then
                log.error("Container targeting is not supported for groups: '" .. target .. "'.")
                return false
            end

            local group_name = string.sub(target, 2)
            local group_recipes = groups[group_name]

            if group_recipes == nil then
                log.error("Unknown recipe group '" .. target .. "'.")
                return false
            end

            table.append(untangled, group_recipes)

        -- 2. Handle specific edge cases (help or empty string)
        elseif (target == "help" or target == "") then
            table.insert(untangled, target)

        -- 3. Handle individual recipe targeting
        else
            if not config__has_recipe(context, target) then
                log.error("Recipe '" .. target .. "' not found in config.")
                return false
            end

            table.insert(untangled, target)
        end
    end

    local final_untangled = table.remove_duplicates(untangled)

    if log.debug_enabled and not table.is_nil_or_empty(final_untangled) then
        log.debug("Untangled - " .. table.concat(final_untangled, " "))
    end

    return final_untangled
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Command
--
-- ------------------------------------------------------------------------- --

---Validates a command configuration table within a recipe, ensuring the command string and container name are specified.
---@param command_table table The command table to validate.
---@param recipe table The recipe containing the command.
---@return boolean True if the command is valid, false otherwise.
local function mode_command__validate(command_table, recipe)
    if type(command_table) ~= "table" then error("command_table must be a table", 2) end
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    if string.is_nil_or_empty(command_table.container) and type(command_table.container) ~= "number" then
        log.error("No container in command table set!")
        return false
    end
    if string.is_nil_or_empty(command_table.execute) then
        log.error("No command in command table set!")
        return false
    end
    -- validate container name : APP *APP and 1
    return true
end

---Constructs and executes a Podman command to run a predefined command within a recipe's container.
---@param context table Application context.
---@param recipe table The recipe containing the command and container definitions.
---@param command_table table The specific command configuration to execute.
local function mode_command__execute(context, recipe, command_table)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    if type(command_table) ~= "table" then error("command_table must be a table", 2) end
    local commands = table.create(8)
    commands[1] = "podman exec -it"

    if command_table.user ~= nil then
        commands[#commands + 1] = "-u"
        commands[#commands + 1] = string.escape_shell(tostring(command_table.user))
    end

    local container_name = recipe__resolve_container_name(recipe, command_table.container)
    if not container_name then
        log.error("Container '" .. tostring(command_table.container) .. "' not found in recipe '" .. recipe.name .. "'.")
        return false
    end

    commands[#commands + 1] = string.escape_shell(container_name)
    commands[#commands + 1] = command_table.execute

    system.exec(table.concat(commands, " "), {
        prefix = "Execute command '" .. command_table.execute .. "' in container '" .. container_name .. "': ",
        simulate = context.flags.simulate
    })
end

---Displays the help text for the command mode, outlining usage, actions, and options.
---@param context table Application context.
local function mode_command__help(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.print("PodScript " .. get_version_string() .. " - Command Mode\n")
    log.print("Execute a command defined in a recipe for a container.")
    log.print("Usage: pods command [OPTIONS] [ACTION] RECIPE [COMMAND|INDEX]")
    log.print("   or: lua pods.lua command [OPTIONS] [ACTION] RECIPE [COMMAND|INDEX]\n")
    log.print("ACTIONS:")
    log.print("  exec               execute a command defined in a recipe (default when COMMAND is provided)")
    log.print("  list               list all valid commands for a recipe (default)")
    log.print("  help               display this help text\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output")
    log.print("  --simulate         preview generated commands without executing them\n")
    log.print("RECIPE:")
    log.print("  *                  name of the recipe\n")
    log.print("COMMAND|INDEX:")
    log.print("  *                  command by name defined in recipe to execute")
    log.print("  <number>           command by numeric index defined in recipe to execute")
end

---Retrieves and sorts all valid commands defined within a recipe's pod configuration.
---@param recipe table The recipe to inspect.
---@param suppress_warnings boolean|nil True to suppress warnings for commands missing descriptions.
---@return table An array of valid command tables, each containing the command name, description, and original table.
local function mode_command__get_valid_commands(recipe, suppress_warnings)
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    if table.is_nil_or_empty(recipe.pod.commands) then
        return {}
    end

    local command_count = table.size(recipe.pod.commands)
    local sorted_commands = table.create(command_count)
    for command, _ in pairs(recipe.pod.commands) do
        table.insert(sorted_commands, command)
    end
    table.sort(sorted_commands)

    local valid_commands = table.create(command_count)
    for i = 1, #sorted_commands do
        local command = sorted_commands[i]
        local command_table = recipe.pod.commands[command]
        local description = command_table.description
        if string.is_nil_or_empty(description) then
            if not suppress_warnings then
                log.warning("Command '" .. command .. "' has no description.")
            end
            description = ""
        end
        table.insert(valid_commands, { name = command, desc = description, table = command_table })
    end
    return valid_commands
end

---Lists all predefined commands available for a specified recipe, formatting them for display.
---@param context table Application context.
---@param recipe table The loaded recipe containing the commands.
---@param target string The name of the target recipe.
local function mode_command__list(context, recipe, target)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    if table.is_nil_or_empty(recipe.pod.commands) then
        log.print("There are no commands defined in recipe '" .. target .. "'.")
        return
    end

    local valid_commands = mode_command__get_valid_commands(recipe)

    if #valid_commands == 0 then
        log.print("There is no valid command in recipe '" .. target .. "'.")
        return
    end

    log.print("Commands for recipe '" .. target .. "':")
    for i = 1, #valid_commands do
        local prefix = i .. ")"
        if #valid_commands > 9 and i < 10 then
            prefix = " " .. prefix
        end
        if string.is_nil_or_empty(valid_commands[i].desc) then
            log.print("  " .. prefix .. " " .. valid_commands[i].name)
        else
            log.print("  " .. prefix .. " " .. valid_commands[i].name .. ": " .. valid_commands[i].desc)
        end
    end
end

---Handles the command mode, parsing arguments to list or execute predefined recipe commands.
---@param context table Application context containing parsed flags and parameters.
local function mode_command__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.debug("Command mode is used.")

    local p1 = context.parameters[1]
    local p2 = context.parameters[2]
    local p3 = context.parameters[3]

    if string.is_nil_or_empty(p1) or p1 == "help" then
        mode_command__help(context)
        return
    end

    local action, target, command_name

    if p1 == "list" or p1 == "exec" then
        action = p1
        target = p2
        command_name = p3
    else
        target = p1
        if string.is_nil_or_empty(p2) then
            action = "list"
        else
            action = "exec"
            command_name = p2
        end
    end

    if string.is_nil_or_empty(target) then
        if action == "list" then
            log.error("Missing recipe name for command list.")
        elseif action == "exec" then
            log.error("Missing recipe name for command exec.")
        end
        return
    end

    local recipe = recipe__load(context.config.recipes.path, target)
    if recipe ~= nil and recipe__validate(context, recipe, target) then
        if action == "list" then
            mode_command__list(context, recipe, target)
        elseif action == "exec" then
            if string.is_nil_or_empty(command_name) then
                log.error("Missing command for recipe '" .. target .. "'.")
                return
            end

            local command_table = nil
            local command_num = tonumber(command_name)

            if command_num ~= nil then
                local valid_commands = mode_command__get_valid_commands(recipe, true)
                if command_num > 0 and command_num <= #valid_commands then
                    command_table = valid_commands[command_num].table
                    command_name = valid_commands[command_num].name
                end
            elseif not table.is_nil_or_empty(recipe.pod.commands) then
                command_table = recipe.pod.commands[command_name]
            end

            if command_table == nil then
                log.error("Command '" .. command_name .. "' not found in recipe '" .. target .. "'.")
                return
            end
            if mode_command__validate(command_table, recipe) then
                mode_command__execute(context, recipe, command_table)
            end
        end
    end
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Connect
--
-- ------------------------------------------------------------------------- --

---Displays the help text for the connect mode, outlining usage, actions, and target formatting.
---@param context table Application context.
local function mode_connect__help(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.print("PodScript " .. get_version_string() .. " - Connect Mode\n")
    log.print("Connect to a running container with an interactive shell.")
    log.print("Usage: pods connect [OPTIONS] [<action>] <target>")
    log.print("   or: lua pods.lua connect [OPTIONS] [<action>] <target>\n")
    log.print("ACTIONS:")
    log.print("  shell              open an interactive shell (default)")
    log.print("  help               display this help\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output")
    log.print("  --simulate         preview generated commands without executing them\n")
    log.print("TARGET:")
    log.print("  <recipe>             connect to the container (if the recipe has exactly 1 container)")
    log.print("  <recipe>/<container> connect to a specific container (index, relative, absolute)")
    log.print("  <absolute_name>      connect directly to an absolute container name\n")
end

---Resolves the target container and spawns an interactive shell connection via Podman.
---@param context table Application context.
---@param target string The target container identifier (recipe name or absolute container name).
---@return boolean True if the connection command succeeds, false otherwise.
local function mode_connect__shell(context, target)
    if type(context) ~= "table" then error("context must be a table", 2) end

    local recipe_name, container_spec = string.match(target, "^([^/]+)/(.*)$")
    if not recipe_name then
        recipe_name = target
        container_spec = nil
    end

    local abs_container_name

    local recipe_file = util.build_full_path(context.config.recipes.path, recipe_name, ".lua")
    local recipe_exists = system.file_exists(recipe_file)

    local loaded_recipe
    if recipe_exists then
        loaded_recipe = recipe__load(context.config.recipes.path, recipe_name)
    end

    if recipe_exists then
        if not loaded_recipe then
            log.error("Recipe '" .. recipe_name .. "' could not be loaded.")
            return false
        end

        if not recipe__validate(context, loaded_recipe, recipe_name) then
            log.error("Recipe '" .. recipe_name .. "' is invalid.")
            return false
        end

        if not container_spec or container_spec == "" then
            if #loaded_recipe.containers == 1 then
                container_spec = "1"
            else
                log.error("Recipe '" .. recipe_name .. "' has multiple containers. Please specify one explicitly.")
                return false
            end
        end

        abs_container_name = recipe__resolve_container_name(loaded_recipe, container_spec)
        if not abs_container_name then
            log.error("Container '" .. container_spec .. "' not found in recipe '" .. recipe_name .. "'.")
            return false
        end
    else
        if not container_spec or container_spec == "" then
            -- Fallback to absolute container name if no recipe matches
            abs_container_name = recipe_name
        else
            log.error("Recipe '" .. recipe_name .. "' does not exist.")
            return false
        end
    end

    if not context.flags.simulate then
        if not system.container_exists(abs_container_name) then
            if not recipe_exists and (not container_spec or container_spec == "") then
                log.error("Target '" .. abs_container_name .. "' does not exist.")
            else
                log.error("Container '" .. abs_container_name .. "' is not running or does not exist.")
            end
            return false
        end
    end

    local escaped_name = string.escape_shell(abs_container_name)
    local command_str = "podman exec -it " .. escaped_name .. " sh -c 'command -v bash >/dev/null 2>&1 && exec bash || exec sh'"

    local success = system.exec(command_str, {
        simulate = context.flags.simulate,
        interactive = true,
        silent = true,
        prefix = "Execute connect command: "
    })
    return success
end

---Handles the connect mode, parsing arguments and invoking the shell connection.
---@param context table Application context containing parsed flags and parameters.
local function mode_connect__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    local action = context.parameters[1]
    local target = context.parameters[2]

    if action == "help" or string.is_nil_or_empty(action) then
        mode_connect__help(context)
        return
    end

    if action ~= "shell" then
        if not string.is_nil_or_empty(target) then
            log.error("Invalid action '" .. action .. "' or too many arguments.")
            return
        end
        target = action
        action = "shell"
    end

    if string.is_nil_or_empty(target) then
        log.error("No container target specified.")
        return
    end

    if string.begins_with(target, "@") then
        log.error("Groups are not supported for connect. Please specify a single target.")
        return
    end

    if #context.parameters > 2 then
        log.error("Connect command only supports a single target.")
        return
    end

    mode_connect__shell(context, target)
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Recipe
--
-- ------------------------------------------------------------------------- --

---Opens a designated recipe file in the configured text editor.
---@param context table Application context defining the editor and paths.
---@param name string The name of the recipe to edit.
local function mode_recipe__edit(context, name)
    if type(context) ~= "table" then error("context must be a table", 2) end
    local found = name
    if found == nil then return end

    local editor = context.config.editor
    if editor == "" then
        log.error("No editor configured.")
        return
    end

    local recipe_path = context.config.recipes.path
    local full_path = util.build_full_path(recipe_path, name, ".lua")

    local command = editor .. " " .. string.escape_shell(full_path)
    system.exec(command, { simulate = context.flags.simulate, interactive = true })
end

---Displays the help text for the recipe mode, outlining usage, actions, and options.
local function mode_recipe__help()
    log.print("PodScript " .. get_version_string() .. "\n")
    log.print("Usage: pods recipe [OPTIONS] ACTION NAME")
    log.print("   or: lua pods.lua recipe [OPTIONS] ACTION NAME\n")
    log.print("OPTIONS:")
    log.print("  --all              include unconfigured recipes found on disk")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output\n")
    log.print("ACTIONS:")
    log.print("  help               display this help and exit")
    log.print("  edit               edit recipe")
    log.print("  list               list all recipes")
    log.print("  show               show recipe\n")
    log.print("NAME:")
    log.print("  *                  name of the recipe")
end

---Discovers and formats all mapped recipes (and optionally unlinked recipe files) for display.
---@param context table Application context containing configuration paths and flags.
local function mode_recipe__list(context)
    if type(context) ~= "table" then error("context must be a table", 2) end

    local config = context.config or {}
    local recipes = config.recipes or {}
    local flags = context.flags or {}

    local show_all = flags.all

    local recipe_map = {}
    local recipe_list = {}

    local groups = recipes.groups or {}
    if not table.is_nil_or_empty(groups) then
        for _, group_targets in pairs(groups) do
            if type(group_targets) == "table" then
                for _, target in ipairs(group_targets) do
                    if type(target) == "string" and not string.begins_with(target, "@") then
                        local clean_target = string.trim(target)
                        if clean_target ~= "" and not recipe_map[clean_target] then
                            recipe_map[clean_target] = true
                            recipe_list[#recipe_list + 1] = clean_target
                        end
                    end
                end
            end
        end
    end

    table.sort(recipe_list)

    local unreferenced = {}
    local recipes_path = recipes.path or ""
    local recipes_files = system.list_directory(recipes_path, "%.lua$")
    if recipes_files then
        for _, file in ipairs(recipes_files) do
            local name = string.gsub(file, "%.lua$", "")
            if not recipe_map[name] then
                table.insert(unreferenced, file)
            end
        end
    end
    table.sort(unreferenced)

    if #recipe_list == 0 and (not show_all or #unreferenced == 0) then
        log.print("There are no recipes defined in config.")
        return
    end

    local total_count = #recipe_list
    if show_all then
        total_count = total_count + #unreferenced
    end

    if #recipe_list > 0 then
        log.print("Recipes:")
        local entries = {}
        local max_length = 0
        for i = 1, #recipe_list do
            local target = recipe_list[i]
            local prefix = i .. ")"
            if total_count > 9 and i < 10 then
                prefix = " " .. prefix
            end

            local recipe = recipe__load(recipes_path, target, true)
            local recipe_name = ""
            local description = ""

            if type(recipe) == "table" then
                if not string.is_nil_or_empty(recipe.name) then
                    recipe_name = string.trim(tostring(recipe.name))
                end
                if not string.is_nil_or_empty(recipe.description) then
                    description = string.trim(tostring(recipe.description))
                end
            end

            local entry = target
            if recipe_name ~= "" then
                entry = entry .. " (" .. recipe_name .. ")"
            end
            if description ~= "" then
                entry = entry .. ": " .. description
            end

            local line = "  " .. prefix .. " " .. entry

            local path = util.build_full_path(recipes_path, target, ".lua")
            local status = "[OK]"
            if not system.file_exists(path) then
                status = "[NOT FOUND]"
            end

            local len = string.visible_length(line)
            if len > max_length then
                max_length = len
            end

            table.insert(entries, {line = line, status = status})
        end

        local target_column = math.max(44, max_length + 1)
        for _, entry in ipairs(entries) do
            log.print(util.format_line(entry.line, entry.status, target_column))
        end
    end

    if show_all and #unreferenced > 0 then
        if #recipe_list > 0 then
            log.print("")
        end
        log.print("Unlinked Recipe Files:")
        local unref_entries = {}
        local max_length = 0
        for i = 1, #unreferenced do
            local file = unreferenced[i]
            local index = #recipe_list + i
            local prefix = index .. ")"
            if total_count > 9 and index < 10 then
                prefix = " " .. prefix
            end
            local line = "  " .. prefix .. " " .. file
            local len = string.visible_length(line)
            if len > max_length then
                max_length = len
            end
            table.insert(unref_entries, {line = line, status = "[UNREFERENCED]"})
        end

        local target_column = math.max(44, max_length + 1)
        for _, entry in ipairs(unref_entries) do
            log.print(util.format_line(entry.line, entry.status, target_column))
        end
    end
end

---Reads and outputs the content of a specified recipe file directly to the console.
---@param context table Application context containing configuration paths.
---@param name string The name of the recipe file to display.
local function mode_recipe__show(context, name)
    if type(context) ~= "table" then error("context must be a table", 2) end
    local found = name
    if found == nil then return end

    local recipe_path = context.config.recipes.path
    local full_path = util.build_full_path(recipe_path, name, ".lua")

    local lines = system.read_file_content_by_line(full_path)
    if not lines then return end

    for i = 1, #lines do
        local prefix = string.format("%3d: ", i)
        log.print(prefix .. lines[i])
    end
end

---Handles the recipe mode, dispatching execution to list, edit, show, or display help.
---@param context table Application context containing parsed flags and parameters.
local function mode_recipe__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.debug("Recipe mode is used.")
    local action = context.parameters[1]
    if string.is_nil_or_empty(action) then
        mode_recipe__list(context)
        return
    end
    if action == "help" then
        mode_recipe__help()
        return
    end
    if action == "list" then
        mode_recipe__list(context)
        return
    end

    local actions = {
        edit = mode_recipe__edit,
        show = mode_recipe__show
    }
    local execute = actions[action]
    local name = context.parameters[2]

    if execute == nil then
        execute = mode_recipe__show
        name = action
    end

    if string.is_nil_or_empty(name) then
        log.error("No recipe name given.")
        return
    end

    if string.begins_with(name, "@") then
        log.error("Groups are not supported in recipe mode.")
        return
    end

    if string.find(name, "/") then
        log.error("Pod/container targeting is not supported in recipe mode.")
        return
    end

    if not config__has_recipe(context, name) then
        log.error("Recipe '" .. name .. "' not found in configuration!")
        return
    end

    execute(context, name)
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Config
--
-- ------------------------------------------------------------------------- --

---Opens the configuration file in the user's preferred editor.
---@param context table Application context containing the configured editor and file path.
local function mode_config__edit(context)
    if type(context) ~= "table" then error("context must be a table", 2) end

    local editor = context.config.editor
    if editor == "" then
        log.error("No editor configured.")
        return
    end
    local command = editor .. " " .. string.escape_shell(context.config.path)
    system.exec(command, { simulate = context.flags.simulate, interactive = true })
end
---Displays the help text for the config mode, detailing available actions and options.
local function mode_config__help()
    log.print("PodScript " .. get_version_string() .. "\n")
    log.print("Usage: pods config [OPTIONS] ACTION")
    log.print("   or: lua pods.lua config [OPTIONS] ACTION\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output\n")
    log.print("ACTIONS:")
    log.print("  help               display this help and exit")
    log.print("  edit               edit config")
    log.print("  show               show config")
end

---Displays the current configuration, including settings, validated directories, and recipe groups.
---@param context table Application context containing the configuration data.
local function mode_config__show(context)
    if type(context) ~= "table" then error("context must be a table", 2) end

    local config_path_str = tostring(context.config.path)
    if not string.is_nil_or_empty(context.config.path) then
        config_path_str = system.get_absolute_path(context.config.path)
    end
    log.print("Configuration: " .. config_path_str)
    log.print("")

    log.print("Settings:")
    log.print("  Editor:       " .. tostring(context.config.editor))
    log.print("  Simulate:     " .. tostring(context.config.simulate))
    log.print("")

    log.print("Directories:")

    local dir_entries = {}
    local dir_max = 0

    local pods_path = context.config.pods.path or ""
    local pods_status = "[NOT FOUND]"
    if system.directory_exists(pods_path) then
        pods_status = "[OK]"
    end
    local abs_pods_path = system.get_absolute_path(pods_path)
    local pods_line = string.format("  %-14s%s", "Pods:", abs_pods_path)
    local pods_len = string.visible_length(pods_line)
    if pods_len > dir_max then dir_max = pods_len end
    table.insert(dir_entries, {line = pods_line, status = pods_status})

    local recipes_path = context.config.recipes.path or ""
    local recipes_status = "[NOT FOUND]"
    local recipes_files = system.list_directory(recipes_path, "%.lua$")
    if system.directory_exists(recipes_path) then
        local count = recipes_files and #recipes_files or 0
        recipes_status = string.format("[OK, %d recipes found]", count)
    end
    local abs_recipes_path = system.get_absolute_path(recipes_path)
    local recipes_line = string.format("  %-14s%s", "Recipes:", abs_recipes_path)
    local recipes_len = string.visible_length(recipes_line)
    if recipes_len > dir_max then dir_max = recipes_len end
    table.insert(dir_entries, {line = recipes_line, status = recipes_status})

    local dir_target = math.max(44, dir_max + 1)
    for _, entry in ipairs(dir_entries) do
        log.print(util.format_line(entry.line, entry.status, dir_target))
    end
    log.print("")

    log.print("Groups:")

    local groups = context.config.recipes.groups or {}
    local group_names = {}
    for g, _ in pairs(groups) do
        table.insert(group_names, g)
    end
    table.sort(group_names)

    local referenced_recipes = {}
    local validation_cache = {}
    local missing_recipes = {}

    local print_queue = {}
    local max_len = 0

    for i, g in ipairs(group_names) do
        table.insert(print_queue, { text = "  • " .. g })
        local elements = groups[g]
        for j, el in ipairs(elements) do
            local is_last = (j == #elements)
            local branch = is_last and "└── " or "├── "

            if string.begins_with(el, "@") then
                local subgroup_name = string.sub(el, 2)
                table.insert(print_queue, { text = "    " .. branch .. el })

                local sub_elements = groups[subgroup_name]
                if not sub_elements then
                    table.insert(print_queue, { text = "    " .. (is_last and "    " or "│   ") .. "└── [MISSING GROUP]" })
                else
                    for k, sub_el in ipairs(sub_elements) do
                        local is_sub_last = (k == #sub_elements)
                        local sub_branch = is_sub_last and "└── " or "├── "

                        local status = "[OK]"
                        referenced_recipes[sub_el] = true
                        if validation_cache[sub_el] == nil then
                            local path = util.build_full_path(recipes_path, sub_el, ".lua")
                            validation_cache[sub_el] = system.file_exists(path)
                        end
                        if not validation_cache[sub_el] then
                            status = "[NOT FOUND]"
                            missing_recipes[sub_el] = true
                        end

                        local line = string.format("    %s%s%s", (is_last and "    " or "│   "), sub_branch, sub_el)
                        local len = string.visible_length(line)
                        if len > max_len then max_len = len end
                        table.insert(print_queue, { line = line, status = status })
                    end
                end
            else
                local status = "[OK]"
                referenced_recipes[el] = true
                if validation_cache[el] == nil then
                    local path = util.build_full_path(recipes_path, el, ".lua")
                    validation_cache[el] = system.file_exists(path)
                end
                if not validation_cache[el] then
                    status = "[NOT FOUND]"
                    missing_recipes[el] = true
                end

                local line = string.format("    %s%s", branch, el)
                local len = string.visible_length(line)
                if len > max_len then max_len = len end
                table.insert(print_queue, { line = line, status = status })
            end
        end
        if i < #group_names then
            table.insert(print_queue, { text = "    " })
        end
    end

    local target_column = math.max(44, max_len + 1)
    for _, item in ipairs(print_queue) do
        if item.text then
            log.print(item.text)
        else
            log.print(util.format_line(item.line, item.status, target_column))
        end
    end

    local unreferenced = {}
    if recipes_files then
        for _, file in ipairs(recipes_files) do
            local name = string.gsub(file, "%.lua$", "")
            if not referenced_recipes[name] then
                table.insert(unreferenced, file)
            end
        end
    end

    local missing_list = {}
    for m, _ in pairs(missing_recipes) do table.insert(missing_list, m) end
    table.sort(missing_list)
    table.sort(unreferenced)

    if #missing_list > 0 or #unreferenced > 0 then
        log.print("")
        log.print("Validation Summary:")
        if #missing_list > 0 then
            if #missing_list == 1 then
                log.print("- Recipe file for '" .. missing_list[1] .. "' not found!")
            else
                local formatted = {}
                for i = 1, #missing_list - 1 do
                    table.insert(formatted, "'" .. missing_list[i] .. "'")
                end
                log.print("- Recipe files for " .. table.concat(formatted, ", ") .. " and '" .. missing_list[#missing_list] .. "' not found!")
            end
        end
        if #unreferenced > 0 then
            if #unreferenced == 1 then
                log.print("- Potentially unreferenced recipe file '" .. unreferenced[1] .. "' found!")
            else
                local formatted = {}
                for i = 1, #unreferenced - 1 do
                    table.insert(formatted, "'" .. unreferenced[i] .. "'")
                end
                log.print("- Potentially unreferenced recipe files " .. table.concat(formatted, ", ") .. " and '" .. unreferenced[#unreferenced] .. "' found!")
            end
        end
    end
end

---Handles the config mode, dispatching to the appropriate sub-action (show, edit, help).
---@param context table Application context containing parsed flags and parameters.
local function mode_config__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end

    log.debug("Config mode is used.")
    local action = context.parameters[1]
    if string.is_nil_or_empty(action) then
        action = "show"
    end
    local actions = {
        help = mode_config__help,
        edit = mode_config__edit,
        show = mode_config__show
    }
    local execute = actions[action] or function()
        log.error("Unknown action: " .. tostring(action))
    end
    execute(context)
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Default
--
-- ------------------------------------------------------------------------- --

---Queries Podman and formats the runtime status of managed pods and containers for display.
---@param context table Application context.
---@param targets table Array of recipe names to filter the status output.
local function mode_default__status(context, targets)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if type(targets) ~= "table" then error("targets must be a table", 2) end
    local query_command = 'podman ps -a --format "{{.ID}};;;{{.Image}};;;{{.Command}};;;{{.CreatedAt}};;;{{.Status}};;;{{.Ports}};;;{{.Names}};;;{{.PodName}};;;{{.Restarts}}"'
    local lines = system.exec_capture(query_command)
    if not lines then
        log.error("Failed to query podman status.")
        return
    end

    local podman_containers = {}
    for i = 1, #lines do
        local parts = string.split(lines[i], ";;;")
        if #parts >= 9 then
            podman_containers[#podman_containers + 1] = {
                id = parts[1],
                image = parts[2],
                command = parts[3],
                created = parts[4],
                status = parts[5],
                ports = parts[6],
                names = parts[7],
                pod = parts[8],
                restarts = parts[9]
            }
        end
    end

    local display_containers = {}
    local managed_expected = {}

    local targets_to_resolve = {}
    if not table.is_nil_or_empty(targets) then
        for i = 1, #targets do
            targets_to_resolve[#targets_to_resolve + 1] = targets[i]
        end
    elseif not context.flags.all then
        -- resolve all known recipes
        if context.config.recipes and context.config.recipes.groups then
            local recipe_map = {}
            for _, group_targets in pairs(context.config.recipes.groups) do
                if type(group_targets) == "table" then
                    for _, target in ipairs(group_targets) do
                        if type(target) == "string" and not string.begins_with(target, "@") then
                            local clean_target = string.trim(target)
                            if clean_target ~= "" and not recipe_map[clean_target] then
                                recipe_map[clean_target] = true
                                targets_to_resolve[#targets_to_resolve + 1] = clean_target
                            end
                        end
                    end
                end
            end
        end
    end

    for i = 1, #targets_to_resolve do
        local target = targets_to_resolve[i]
        local recipe = recipe__load(context.config.recipes.path, target, true)
        if recipe ~= nil and recipe__validate(context, recipe, target) then
            for id = 1, #recipe.containers do
                local container = recipe.containers[id]
                container__ensure_name(container, recipe.pod.name, tostring(id))
                managed_expected[container.name] = {
                    recipe = target,
                    pod_name = recipe.pod.name
                }
            end
        end
    end

    if not context.flags.all then
        local found_names = {}
        for i = 1, #podman_containers do
            local pc = podman_containers[i]
            if managed_expected[pc.names] then
                display_containers[#display_containers + 1] = pc
                found_names[pc.names] = true
            end
        end

        for expected_name, info in pairs(managed_expected) do
            if not found_names[expected_name] then
                display_containers[#display_containers + 1] = {
                    id = "-",
                    image = "-",
                    command = "-",
                    created = "-",
                    status = "Not Found",
                    ports = "-",
                    names = expected_name,
                    pod = info.pod_name,
                    restarts = "-"
                }
            end
        end
    else
        display_containers = podman_containers
        local found_names = {}
        for i = 1, #podman_containers do
            found_names[podman_containers[i].names] = true
        end

        if not table.is_nil_or_empty(targets) then
            for expected_name, info in pairs(managed_expected) do
                if not found_names[expected_name] then
                    display_containers[#display_containers + 1] = {
                        id = "-",
                        image = "-",
                        command = "-",
                        created = "-",
                        status = "Not Found",
                        ports = "-",
                        names = expected_name,
                        pod = info.pod_name,
                        restarts = "-"
                    }
                end
            end
        end
    end

    if #display_containers == 0 then
        log.print("No containers found.")
        return
    end

    table.sort(display_containers, function(a, b)
        if a.pod == b.pod then
            return a.names < b.names
        end
        return a.pod < b.pod
    end)

    local cols = {}
    if context.flags.full then
        cols = { "ID", "POD", "NAMES", "STATUS", "RESTARTS", "CREATED", "IMAGE", "COMMAND", "PORTS" }
    else
        cols = { "ID", "POD", "NAMES", "STATUS", "RESTARTS", "CREATED" }
    end

    local pad_right = function(str, len)
        str = str or ""
        if #str < len then
            return str .. string.rep(" ", len - #str)
        end
        return str
    end

    local max_lengths = {}
    for i = 1, #cols do
        local col = cols[i]
        max_lengths[col] = #col
    end

    for i = 1, #display_containers do
        local c = display_containers[i]
        for j = 1, #cols do
            local col = cols[j]
            local val = tostring(c[string.lower(col)] or "")
            if #val > max_lengths[col] then
                max_lengths[col] = #val
            end
        end
    end

    local header_line = ""
    for i = 1, #cols do
        local col = cols[i]
        header_line = header_line .. pad_right(col, max_lengths[col])
        if i < #cols then
            header_line = header_line .. "   "
        end
    end
    log.print(header_line)

    for i = 1, #display_containers do
        local c = display_containers[i]
        local row_line = ""
        for j = 1, #cols do
            local col = cols[j]
            local val = tostring(c[string.lower(col)] or "")
            row_line = row_line .. pad_right(val, max_lengths[col])
            if j < #cols then
                row_line = row_line .. "   "
            end
        end
        log.print(row_line)
    end
end

---Displays the help text for the status action within the default mode.
---@param context table Application context.
local function mode_default__status_help(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.print("PodScript " .. get_version_string() .. " - Status\n")
    log.print("Display the runtime status of pods and containers.")
    log.print("Usage: pods status [OPTIONS] [TARGETS]")
    log.print("   or: lua pods.lua status [OPTIONS] [TARGETS]\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output")
    log.print("  --simulate         preview generated commands without executing them")
    log.print("  --all              include all unmanaged podman containers")
    log.print("  --full             display extended container information (image, command, ports)\n")
    log.print("TARGETS:")
    log.print("  *                  names of recipes or groups to filter (defaults to all managed recipes)")
end
---Handles the default mode, orchestrating lifecycle actions (create, recreate, remove, update) or displaying status.
---@param context table Application context containing parsed flags and parameters.
local function mode_default__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.debug("Default mode is used.")
    local action = context.parameters[1]

    -- validate action
    if string.is_nil_or_empty(action) then
        log.error("No action set.")
        return
    end
    if not table.contains({ "create", "recreate", "remove", "update", "status" }, action) then
        log.error("Unknown action '" .. action .. "'.")
        return
    end

    local targets = table.sub(context.parameters, 2)

    -- validate targets
    if table.is_nil_or_empty(targets) and action ~= "status" then
        log.error("No targets set.")
        return
    end

    if action == "status" then
        if not table.is_nil_or_empty(targets) and targets[1] == "help" then
            mode_default__status_help(context)
        else
            mode_default__status(context, targets)
        end
        return
    end

    local untangled_targets = config__untangle(context, targets)
    if not untangled_targets then return end

    -- handle recipes
    local recipe_path = context.config.recipes.path
    local pod_actions = {
        create   = pod__create,
        recreate = pod__recreate,
        remove   = pod__remove,
        update   = pod__update,
    }
    for i = 1, #untangled_targets do
        local target = untangled_targets[i]
        -- load recipe
        local recipe = recipe__load(recipe_path, target)
        -- handle recipe
        if recipe ~= nil and recipe__validate(context, recipe, target) then
            --action is valid at this point
            pod_actions[action](recipe, context.flags.simulate)
        end
    end
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Logs
--
-- ------------------------------------------------------------------------- --

---Displays the help text for the logs mode, detailing usage, actions, and available flags.
---@param context table Application context.
local function mode_logs__help(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.print("PodScript " .. get_version_string() .. " - Logs Mode\n")
    log.print("Show or follow logs for a recipe's pod or container.")
    log.print("Usage: pods logs [OPTIONS] [<action>] <recipe>[/container]")
    log.print("   or: lua pods.lua logs [OPTIONS] [<action>] <recipe>[/container]\n")
    log.print("ACTIONS:")
    log.print("  show               fetch and display logs, then exit (default)")
    log.print("  follow             fetch and follow logs")
    log.print("  help               display this help\n")
    log.print("OPTIONS:")
    log.print("  --tail=<n>         output the specified number of lines at the end")
    log.print("  --since=<time>     show logs since timestamp")
    log.print("  --until=<time>     show logs until timestamp")
    log.print("  --timestamps       show timestamps in the log output")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output")
    log.print("  --simulate         preview generated commands without executing them\n")
    log.print("TARGET:")
    log.print("  <recipe>             show logs for all containers in the recipe's pod")
    log.print("  <recipe>/<container> filter logs to a specific container (index, relative, absolute)")
end

---Executes the podman log command for a target recipe's pod or specific container.
---@param context table Application context containing flags (e.g., since, tail).
---@param action string The logging action (e.g., 'show' or 'follow').
---@param target string The recipe and optional container specification to fetch logs for.
---@return boolean True if the logging command is successfully dispatched, false otherwise.
local function mode_logs__execute(context, action, target)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if string.is_nil_or_empty(target) then
        log.error("No recipe target specified.")
        return false
    end

    local recipe_name, container_spec = string.match(target, "^([^/]+)/(.*)$")
    if not recipe_name then
        recipe_name = target
        container_spec = nil
    end

    -- Load recipe
    local loaded_recipe = recipe__load(context.config.recipes.path, recipe_name)
    if not loaded_recipe then
        log.error("Recipe '" .. recipe_name .. "' could not be loaded.")
        return false
    end

    if not recipe__validate(context, loaded_recipe, recipe_name) then
        log.error("Recipe '" .. recipe_name .. "' is invalid.")
        return false
    end

    local commands = table.create(16)
    commands[#commands + 1] = "podman"
    commands[#commands + 1] = "pod"
    commands[#commands + 1] = "logs"
    commands[#commands + 1] = "-n"
    commands[#commands + 1] = "--color"

    if action == "follow" then
        commands[#commands + 1] = "-f"
    end

    if context.flags.since then
        commands[#commands + 1] = "--since"
        commands[#commands + 1] = string.escape_shell(tostring(context.flags.since))
    end
    if context.flags["until"] then
        commands[#commands + 1] = "--until"
        commands[#commands + 1] = string.escape_shell(tostring(context.flags["until"]))
    end
    if context.flags.tail then
        commands[#commands + 1] = "--tail"
        commands[#commands + 1] = tostring(context.flags.tail)
    end
    if context.flags.timestamps then
        commands[#commands + 1] = "--timestamps"
    end

    if container_spec and container_spec ~= "" then
        local container_name = recipe__resolve_container_name(loaded_recipe, container_spec)
        if not container_name then
            log.error("Container '" .. container_spec .. "' not found in recipe '" .. recipe_name .. "'.")
            return false
        end
        commands[#commands + 1] = "-c"
        commands[#commands + 1] = string.escape_shell(container_name)
    end

    commands[#commands + 1] = string.escape_shell(loaded_recipe.pod.name)

    local command_str = table.concat(commands, " ")

    local success = system.exec(command_str, {
        simulate = context.flags.simulate,
        interactive = true,
        silent = true,
        prefix = "Execute log command: "
    })
    return success
end

---Handles the logs mode, processing commands to display or stream podman logs.
---@param context table Application context containing parsed flags and parameters.
local function mode_logs__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    local action = context.parameters[1]
    local raw_target = context.parameters[2]

    if action == "help" or string.is_nil_or_empty(action) then
        mode_logs__help(context)
        return
    end

    -- If action is not show, follow or help, it might be the target if the action was omitted
    if action ~= "show" and action ~= "follow" then
        if not string.is_nil_or_empty(raw_target) then
            log.error("Invalid action '" .. action .. "' or too many arguments.")
            return
        end
        raw_target = action
        action = "show"
    end

    if raw_target and string.begins_with(raw_target, "@") then
        log.error("Groups are not supported for logs. Only pods and containers are supported.")
        return
    end

    if #context.parameters > 2 then
        log.error("Logs command only supports a single recipe target.")
        return
    end

    mode_logs__execute(context, action, raw_target)
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Help
--
-- ------------------------------------------------------------------------- --

---Handles the help mode, outputting global usage, available modes, actions, and options.
---@param context table Application context.
local function mode_help__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.print("PodScript " .. get_version_string() .. "\n")
    log.print("Usage: pods [MODE] [OPTIONS] ACTION [TARGETS]")
    log.print("   or: lua pods.lua [MODE] [OPTIONS] ACTION [TARGETS]\n")
    log.print("MODES:")
    log.print("  *                  default mode")
    log.print("  command            execute a command defined in a recipe")
    log.print("  config             manage and inspect configuration")
    log.print("  connect            connect to a running container with an interactive shell")
    log.print("  help               display this help and exit")
    log.print("  init               initialize default configuration and recipe")
    log.print("  logs               show or follow logs for a pod or container")
    log.print("  recipe             inspect and edit recipes\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output")
    log.print("  --simulate         preview generated commands without executing them\n")
    log.print("Valid in default mode only:\n")
    log.print("ACTIONS:")
    log.print("  create             create a new pod")
    log.print("  recreate           removes and then creates a new pod")
    log.print("  remove             remove a running pod")
    log.print("  status             display status of pods and containers")
    log.print("  update             update all defined images of the pod\n")
    log.print("TARGETS:")
    log.print("  *                  names of recipes or groups defined in a config\n")
    log.print("For more: lua pods.lua [MODE] help")
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Init
--
-- ------------------------------------------------------------------------- --

---Generates an initial example recipe and configuration file in the current working directory.
---@param context table Application context defining output paths.
local function mode_init__create(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    local recipe_path = util.build_full_path(".", "recipe", ".lua")
    local config_path = context.config.path or util.build_full_path("config", "", ".lua")

    if system.file_exists(recipe_path) then
        log.error("File '" .. recipe_path .. "' already exists!")
        return
    end

    if system.file_exists(config_path) then
        log.error("File '" .. config_path .. "' already exists!")
        return
    end

    local recipe_content = "return {\n"
        .. "    name = \"Example Pod\",\n"
        .. "    description = \"Example web service pod managed by PodScript.\",\n"
        .. "    pod = {\n"
        .. "        name = \"web-service\",\n"
        .. "        path = \"/pods\",\n"
        .. "        registry = \"docker.io\",\n"
        .. "        publish = {\n"
        .. "            { 8080, 80, \"TCP\" },\n"
        .. "        },\n"
        .. "    },\n"
        .. "    containers = {\n"
        .. "        {\n"
        .. "            name = \"*app\",\n"
        .. "            detach = true,\n"
        .. "            image = \"example:latest\",\n"
        .. "            restart = \"always\",\n"
        .. "        },\n"
        .. "    },\n"
        .. "}\n"
    local config_content = "return {\n"
        .. "    pods = {\n"
        .. "        path = \"/pods\",\n"
        .. "    },\n"
        .. "    recipes = {\n"
        .. "        groups = {\n"
        .. "            all = {\n"
        .. "                \"recipe\",\n"
        .. "            },\n"
        .. "        },\n"
        .. "    },\n"
        .. "}\n"

    if not system.write_file(recipe_path, recipe_content) then
        return
    end
    log.info("Created '" .. recipe_path .. "'.")

    if not system.write_file(config_path, config_content) then
        return
    end
    log.info("Created '" .. config_path .. "'.")
end

---Displays the help text for the init mode, outlining usage, actions, and options.
local function mode_init__help()
    log.print("PodScript " .. get_version_string() .. "\n")
    log.print("Usage: pods init [OPTIONS]")
    log.print("   or: lua pods.lua init [OPTIONS]\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output\n")
    log.print("ACTIONS:")
    log.print("  help               display this help and exit")
end

---Handles the init mode, determining whether to display help or create initialization files.
---@param context table Application context containing parsed flags and parameters.
local function mode_init__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.debug("Init mode is used.")
    local action = context.parameters[1] or ""
    if action == "" then
        mode_init__create(context)
        return
    end

    local actions = {
        help = mode_init__help,
    }
    local execute = actions[action] or function()
        log.error("Unknown action: " .. tostring(action))
    end
    execute()
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Main
--
-- ------------------------------------------------------------------------- --

---Loads the PodScript configuration file and populates the application context. Sets default values for missing fields.
---@param context table The application context object to modify.
---@return boolean True if the configuration was successfully loaded and contains recipes, false otherwise.
local function main__config_load_and_set(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    local config_path = context.config.path

    local config, error, _ = system.load_lua_file(config_path)
    if config == nil then
        if error ~= nil then
            log.error(error)
        end
        log.error("Couldn't load configuration '" .. config_path .. "'!")
        return false
    end

    -- merge loaded config into context.config
    if config.simulate ~= nil then context.config.simulate = config.simulate end
    if config.editor ~= nil then context.config.editor = config.editor end

    if config.pods then
        if config.pods.path ~= nil then context.config.pods.path = config.pods.path end
        for k, v in pairs(config.pods) do
            if k ~= "path" then context.config.pods[k] = v end
        end
    end

    if config.recipes then
        if config.recipes.path ~= nil then context.config.recipes.path = config.recipes.path end
        if config.recipes.groups ~= nil then context.config.recipes.groups = config.recipes.groups end
        for k, v in pairs(config.recipes) do
            if k ~= "path" and k ~= "groups" then context.config.recipes[k] = v end
        end
    end

    -- set default path for recipes
    if string.is_nil_or_empty(context.config.recipes.path) then
        context.config.recipes.path = "."
    end

    -- check recipe values
    if table.is_nil_or_empty(config.recipes) then
        log.error("No recipes defined in config '" .. config_path .. "'!")
        return false
    else
        if table.is_nil_or_empty(config.recipes.groups) then
            log.error("No recipes groups defined in configuration '" .. config_path .. "'!")
            return false
        end
    end

    return true
end

---Parses command-line arguments and populates the context with flags, parameters, and the selected mode.
---@param context table The application context object.
---@param arguments string[] Array of command-line arguments.
---@param modes table Dictionary mapping mode names to their handler functions.
local function main__parse_arguments(context, arguments, modes)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if type(arguments) ~= "table" then error("arguments must be a table", 2) end
    if type(modes) ~= "table" then error("modes must be a table", 2) end
    -- no arguments
    -- don't use table__size, it will be 2 (key -1 and 0 are used)
    if #arguments == 0 then
        context.mode = modes.help
        return
    end
    -- parse arguments
    local has_seen_positional = false
    for i = 1, #arguments do
        local argument = arguments[i]
        if string.begins_with(argument, "--") then
            if string.begins_with(argument, "--config=") then
                local value = string.sub(argument, 10)
                context.config.path = value
                local filename = string.match(value, "([^/]+)$") or value
                local name = string.match(filename, "(.+)%.[^%.]+$") or filename
                context.config.name = name
            elseif argument == "--debug" then
                log.debug_enabled = true
            else
                local parameter, value = util.split_argument(argument)
                context.flags[parameter] = value
            end
            -- check if argument is a mode
        else
            local is_mode = (not has_seen_positional) and modes[argument]
            has_seen_positional = true
            if is_mode then
                context.mode = modes[argument]
            else
                table.insert(context.parameters, argument)
            end
        end
    end
end

---The main entry point for PodScript. Initializes the context, parses arguments, and dispatches to the appropriate mode handler.
---@param arguments string[] Array of command-line arguments passed to the application.
global function main(arguments)
    local modes = {
        command = mode_command__handle,
        config = mode_config__handle,
        connect = mode_connect__handle,
        default = mode_default__handle,
        help = mode_help__handle,
        init = mode_init__handle,
        logs = mode_logs__handle,
        recipe = mode_recipe__handle,
    }

    local context = {
        -- MUTABLE: Populated and mutated by config loaders
        config = {
            name = "config", -- The provided config name
            path = "",       -- The resolved full path to the config file
            simulate = true, -- Default simulate value
            editor = "",     -- Default editor
            pods = { path = "" },
            recipes = { path = ".", groups = {} },
        },

        -- READ-ONLY (RO): Parsed once from CLI
        mode = modes.default,     -- The selected mode handler function
        flags = {},               -- Parsed command-line flags (e.g., { ["--debug"] = true })
        parameters = {},          -- Parsed positional command-line arguments
    }

    -- check lua version
    if not system.check_lua_version() then
        log.error("Lua 5.5 or higher is required.")
        return
    end

    -- check os
    if not system.check_os() then
        log.error("Only Linux is supported.")
        return
    end

    -- check podman version
    if not system.check_podman_version() then
        log.error("Podman 5.8.0 or higher is required.")
        return
    end

    -- check for elevated privileges and prompt for confirmation
    if system.runs_elevated() then
        log.warning("PodScript is running with elevated privileges (sudo).")
        io.write("Are you sure you want to continue? Type 'yes' to proceed: ")
        local input = io.read()
        if input ~= "yes" then
            log.error("Aborting execution.")
            return
        end
    end

    -- parse arguments
    main__parse_arguments(context, arguments, modes)

    log.debug("Debug mode is enabled.")

    -- normalize config name
    local config_name = context.config.name
    if config_name ~= "config" and config_name ~= "" then
        config_name = util.normalize_name(config_name)
    end

    -- build full config path
    local config_full_path = context.config.path
    if config_full_path == "" then
        config_full_path = util.build_full_path(config_name, "", ".lua")
    else
        config_full_path = util.build_full_path(context.config.path, "", ".lua")
    end

    -- print debug message if non-default-configuration is used
    if log.debug_enabled and config_name ~= "config" then
        log.print("DEBUG: Config '" .. config_full_path .. "' is used.")
    end

    context.config.path = config_full_path

    -- handle modes that do not require configuration
    if context.mode == modes.help or context.mode == modes.init then
        context.mode(context)
        return
    end

    -- parse config
    if not main__config_load_and_set(context) then
        return
    end

    -- sync simulate flag with config
    if context.config.simulate then
        context.flags.simulate = true
    end

    if context.flags.simulate then
        log.info("Simulate mode is active.")
    end

    -- handle mode
    context.mode(context)
end

-- prevent excecution when imported from test_suite
if arg[0] ~= "test.lua" then
    -- execute main
    main(arg)
end
