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

local VERSION <const> = "1.4.0"
local BUILD <const> = "207.37d8e9f.dev"

---Get the full version string formatted as 'v<VERSION>+<BUILD>'.
---@return string
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

    ---Print debug message if debug is enabled.
    ---@param ... any
    debug = function(... args)
        if log.debug_enabled then
            log.print("DEBUG: " .. log.format_args(...))
        end
    end,

    ---Print error message.
    ---@param ... any
    error = function(... args)
        log.print("ERROR: " .. log.format_args(...))
    end,

    ---Format variable arguments into a single string separated by spaces.
    ---@param ... any
    ---@return string
    format_args = function(... args)
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
    end,

    ---Print info message.
    ---@param ... any
    info = function(... args)
        log.print("INFO: " .. log.format_args(...))
    end,

    ---Print warning message.
    ---@param ... any
    warning = function(... args)
        log.print("WARNING: " .. log.format_args(...))
    end,
}
-- ------------------------------------------------------------------------- --
--
--    SECTION String
--
-- ------------------------------------------------------------------------- --

---Test if a string begins with another string.
---@param str string
---@param prefix string
---@return boolean
function string.begins_with(str, prefix)
    return str:sub(1, #prefix) == prefix
end

---Test if a string ends with another string.
---@param str string
---@param suffix string
---@return boolean
function string.ends_with(str, suffix)
    return str:sub(- #suffix) == suffix
end

---Escapes a string for safe use in shell commands.
---@param str string|nil
---@param always_quote boolean|nil
---@return string
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

---Test if string is empty or nil.
---@param str string|nil
---@return boolean
function string.is_nil_or_empty(str)
    return str == nil or str == ""
end

---Removes leading and trailing whitespaces.
---@param str string|nil
---@return string
function string.trim(str)
    if str == nil then return "" end
    -- avoid lazy evaluation of '.-' in str:match("^%s*(.-)%s*$")
    return str:match("^()%s*$") and "" or str:match("^%s*(.*%S)")
end

---Splits a string by a given separator.
---@param str string
---@param sep string
---@return table
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
-- ------------------------------------------------------------------------- --
--
--    SECTION Table
--
-- ------------------------------------------------------------------------- --

---Appends one or more sequential tables to another.
---Example: {1,2,3} and {4,5,6} will be {1,2,3,4,5,6}.
---@param target table|nil
---@param ... table|nil
function table.append(target, ...sources)
    if target == nil then return end
    for i = 1, sources.n do
        local source = sources[i]
        if source ~= nil then
            table.move(source, 1, #source, #target + 1, target)
        end
    end
end

---Test if a table contains a value. Only works with sequential tables.
---Returns false if table is nil or value is not found.
---@param target table|nil
---@param value any
---@return boolean
function table.contains(target, value)
    if target == nil then return false end
    for i = 1, #target do
        if (target[i] == value) then return true end
    end
    return false
end


---Get value from table or default if key not found.
---You can use "table and table[key] or default" instead, if there is no false value in table.
---@param target table
---@param key any
---@param default any
function table.get_or_default(target, key, default)
    if target == nil then return default end
    local value = target[key]
    if value ~= nil then
        return value
    end
    return default
end

---Check if a key exists in a table.
---@param target table
---@param key any
---@return boolean
function table.has_key(target, key)
    return target ~= nil and target[key] ~= nil
end

---Test if a table is nil or empty.
---@param target table
---@return boolean
function table.is_nil_or_empty(target)
    return target == nil or next(target) == nil
end

---Merges two or more tables by adding key-value pairs from sources to target.
---If a key from a source table already exists in the target table, its value will be overwritten.
---@param target table
---@param ... table
---@return table
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

---Remove duplicates from a table. Returns a new table and don't modify the original.
---@param target table
---@return table
function table.remove_duplicates(target)
    if target == nil then return {} end
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

---Get table size, including non-numeric keys.
---@param table table
---@return integer
function table.size(table)
    if table == nil then return 0 end
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
end

---Returns a sub-sequence of a sequential table, similar to string.sub.
---@param target table
---@param i integer|nil
---@param j integer|nil
---@return table
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

---Build a full path with given parts.
---@param path string
---@param file_name string
---@param file_extension string
---@return string
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

---Normalizes a string by trimming outer whitespace, replacing internal spaces with underscores, and converting to lowercase.
---@param line string The input string to be normalized.
---@return string # The fully formatted string (e.g., " My  Name " becomes "my_name").
function util.format_line(line, status)
    local extra = 0
    for i = 1, #line do
        local b = line:byte(i)
        if b >= 0x80 and b <= 0xBF then
            extra = extra + 1
        end
    end
    local visible = #line - extra
    local pad = 44 - visible
    if pad < 1 then pad = 1 end
    return line .. string.rep(" ", pad) .. status
end

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

function util.untangle(context, list)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
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
            local target_recipe = target

            -- Verify that the target recipe exists in the configuration groups
            local is_valid_recipe = false
            for _, group_targets in pairs(groups) do
                if table.contains(group_targets, target_recipe) then
                    is_valid_recipe = true
                    break
                end
            end

            if not is_valid_recipe then
                log.error("Recipe '" .. target_recipe .. "' not found in config.")
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
-- ------------------------------------------------------------------------- --
--
--    SECTION Container
--
-- ------------------------------------------------------------------------- --

---Create a container.
---@param container table
---@param pod table
---@param simulate boolean
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
    system.exec(table.concat(commands, " "), "Create container '" .. container.name .. "': ", simulate, false)
end

---Ensure container name.
---@param container table
---@param pod_name string
---@param container_alternate_name string
---@return boolean
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

---Test if container is valid. Container.name is optional.
---@param container table
---@param pod_name string
---@return boolean
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

---Stop and removes a container.
---@param container table
---@param simulate boolean
local function container__remove(container, simulate)
    if type(container) ~= "table" then error("container must be a table", 2) end
    system.exec("podman stop " .. string.escape_shell(container.name), "Stop container '" .. container.name .. "': ", simulate, false)
    system.exec("podman rm " .. string.escape_shell(container.name), "Remove container '" .. container.name .. "': ", simulate, false)
end

---Update a container image.
---@param container table
---@param pod table
---@param simulate boolean
local function container__update(container, pod, simulate)
    if type(container) ~= "table" then error("container must be a table", 2) end
    if type(pod) ~= "table" then error("pod must be a table", 2) end
    local registry = table.get_or_default(container, "registry", pod.registry)
    log.print("Update container '" .. container.name .. "' ...")
    system.exec("podman pull " .. string.escape_shell(registry .. "/" .. container.image), "", simulate, false)
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Recipe
--
-- ------------------------------------------------------------------------- --

---Load PodScript recipe.
---@param recipe_path string
---@param recipe_name string
---@param suppress_errors boolean|nil
---@return table|nil
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

---Validate recipe.
---@param context table
---@param recipe table
---@param file_name string
---@return boolean
local function recipe__validate(context, recipe, file_name)
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    recipe.pod = recipe.pod or {}
    recipe.containers = recipe.containers or {}
    if type(context) ~= "table" then error("context must be a table", 2) end
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
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
        if string.is_nil_or_empty(context.config.pods.path) then
            log.error("No default pod path and pod path in recipe '" .. file_name .. "' set or empty!")
            return false
        else
            -- if pod path not set use default path with pod name as folder name
            local path = util.build_full_path(context.config.pods.path, recipe.pod.name, "")
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

---Resolve a container name from a user specification (index, name, *relative).
---@param recipe table
---@param container_spec string|number
---@return string|nil name
local function recipe__resolve_container_name(recipe, container_spec)
    recipe.pod = recipe.pod or {}
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    recipe.containers = recipe.containers or {}
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

---Create pod and containers.
---@param recipe table
---@param simulate boolean
local function pod__create(recipe, simulate)
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    recipe.pod = recipe.pod or {}
    recipe.containers = recipe.containers or {}
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
    system.exec(table.concat(commands, " "), "Create pod '" .. recipe.name .. "' ('" .. recipe.pod.name .. "'): ",
        simulate, false)

    -- create containers
    local containers = recipe.containers
    for id = 1, #containers do
        local container = containers[id]
        container__ensure_name(container, recipe.pod.name, tostring(id))
        container__create(container, recipe.pod, simulate)
    end
end

---Remove pod and containers.
---@param recipe table
---@param simulate boolean
local function pod__remove(recipe, simulate)
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    recipe.pod = recipe.pod or {}
    recipe.containers = recipe.containers or {}
    -- remove containers
    local containers = recipe.containers
    for id = #containers, 1, -1 do -- reverse order when shutting down containers
        local container = containers[id]
        container__ensure_name(container, recipe.pod.name, tostring(id))
        container__remove(container, simulate)
    end

    -- remove pod
    system.exec("podman pod rm " .. string.escape_shell(recipe.pod.name), "Remove pod '" .. recipe.name .. "' ('" .. recipe.pod.name .. "'): ",
        simulate, false)
end

---Remove and create pod and containers.
---@param recipe table
---@param simulate boolean
local function pod__recreate(recipe, simulate)
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    pod__remove(recipe, simulate)
    pod__create(recipe, simulate)
end

---Update containers of the pod.
---@param recipe table
---@param simulate boolean
local function pod__update(recipe, simulate)
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    recipe.pod = recipe.pod or {}
    recipe.containers = recipe.containers or {}
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
--    SECTION Mode Command
--
-- ------------------------------------------------------------------------- --

---Validates command_table.
local function mode_command__validate(command_table, recipe)
    if type(command_table) ~= "table" then error("command_table must be a table", 2) end
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    recipe.pod = recipe.pod or {}
    recipe.containers = recipe.containers or {}
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

---Build and execute command.
---@param context table
---@param recipe table
---@param command_table table
local function mode_command__execute(context, recipe, command_table)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    recipe.pod = recipe.pod or {}
    recipe.containers = recipe.containers or {}
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

    system.exec(table.concat(commands, " "),
        "Execute command '" .. command_table.execute .. "' in container '" .. container_name .. "': ",
        context.flags.simulate, false)
end

---Print command help.
local function mode_command__help(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    if context.flags.simulate then
        log.print("PodScript " .. get_version_string() .. " - Command Mode (SIMULATED)\n")
        log.print("Simulate the execution of a command defined in a recipe for a container.")
        log.print("Usage: pods simulate command [OPTIONS] RECIPE [COMMAND|INDEX]")
        log.print("   or: lua pods.lua simulate command [OPTIONS] RECIPE [COMMAND|INDEX]\n")
    else
        log.print("PodScript " .. get_version_string() .. " - Command Mode\n")
        log.print("Execute a command defined in a recipe for a container.")
        log.print("Usage: pods command [OPTIONS] RECIPE [COMMAND|INDEX]")
        log.print("   or: lua pods.lua command [OPTIONS] RECIPE [COMMAND|INDEX]\n")
    end
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output\n")
    log.print("RECIPE:")
    log.print("  *                  name of the recipe")
    log.print("COMMAND|INDEX:")
    log.print("  *                  command by name defined in recipe to execute")
    log.print("  <number>           command by numeric index defined in recipe to execute")
    log.print("  list               list all valid commands for a recipe (default)")
end

---Get a list of valid commands for a recipe.
---@param recipe table
---@param suppress_warnings boolean|nil
---@return table
local function mode_command__get_valid_commands(recipe, suppress_warnings)
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    recipe.pod = recipe.pod or {}
    recipe.containers = recipe.containers or {}
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

---List all commands for a recipe.
---@param context table
---@param recipe table
---@param target string
local function mode_command__list(context, recipe, target)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    recipe.pod = recipe.pod or {}
    recipe.containers = recipe.containers or {}
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

---Handle recipe mode.
---@param context table
local function mode_command__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    log.debug("Command mode is used.")
    local name = context.parameters[1]
    local command = context.parameters[2]

    if string.is_nil_or_empty(name) or name == "help" then
        mode_command__help(context)
        return
    end

    if string.is_nil_or_empty(command) then
        command = "list"
    end

    local target = name
    local recipe = recipe__load(context.config.recipes.path, target)
    if recipe ~= nil and recipe__validate(context, recipe, target) then
        if command == "list" then
            mode_command__list(context, recipe, target)
        else
            local command_table = nil
            local command_num = tonumber(command)
            
            if command_num ~= nil then
                local valid_commands = mode_command__get_valid_commands(recipe, true)
                if command_num > 0 and command_num <= #valid_commands then
                    command_table = valid_commands[command_num].table
                    command = valid_commands[command_num].name
                end
            elseif not table.is_nil_or_empty(recipe.pod.commands) then
                command_table = recipe.pod.commands[command]
            end

            if command_table == nil then
                log.error("Command '" .. command .. "' not found in recipe '" .. target .. "'.")
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
--    SECTION Mode Recipe
--
-- ------------------------------------------------------------------------- --

---Edit recipe.
---@param context table
---@param name string
local function mode_recipe__edit(context, name)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
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
    system.exec(command, "", context.flags.simulate, true)
end

---Print config help.
local function mode_recipe__help()
    log.print("PodScript " .. get_version_string() .. "\n")
    log.print("Usage: pods recipe [OPTIONS] ACTION NAME")
    log.print("   or: lua pods.lua recipe [OPTIONS] ACTION NAME\n")
    log.print("OPTIONS:")
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

---List recipes defined in config.
---@param context table
local function mode_recipe__list(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    if table.is_nil_or_empty(context.config.recipes) or table.is_nil_or_empty(context.config.recipes.groups) then
        log.print("There are no recipes defined in config.")
        return
    end

    local recipe_map = {}
    local recipe_list = {}

    for _, group_targets in pairs(context.config.recipes.groups) do
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

    if #recipe_list == 0 then
        log.print("There are no recipes defined in config.")
        return
    end

    table.sort(recipe_list)

    log.print("Recipes:")
    for i = 1, #recipe_list do
        local target = recipe_list[i]
        local prefix = i .. ")"
        if #recipe_list > 9 and i < 10 then
            prefix = " " .. prefix
        end

        local recipe = recipe__load(context.config.recipes.path, target, true)
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

        log.print("  " .. prefix .. " " .. entry)
    end
end

---Show recipe content.
---@param context table
---@param name string
local function mode_recipe__show(context, name)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
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

---Handle recipe mode.
---@param context table
local function mode_recipe__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    log.debug("Recipe mode is used.")
    local action = context.parameters[1]
    if string.is_nil_or_empty(action) or action == "help" then
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
    if execute == nil then
        log.error("Unknown action: " .. tostring(action))
        return
    end

    local name = context.parameters[2]

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

    execute(context, name)
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Config
--
-- ------------------------------------------------------------------------- --

---Edit config.
---@param context table
local function mode_config__edit(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    if type(context) ~= "table" or type(context.config) ~= "table" then
        error("mode_config__edit requires a valid context object", 2)
    end
    local editor = context.config.editor
    if editor == "" then
        log.error("No editor configured.")
        return
    end
    local command = editor .. " " .. string.escape_shell(context.config.path)
    system.exec(command, "", context.flags.simulate, true)
end
---Print config help.
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

---Show config.
---@param context table
local function mode_config__show(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    if type(context) ~= "table" or type(context.config) ~= "table" then
        error("mode_config__show requires a valid context object", 2)
    end

    log.print("Configuration: " .. tostring(context.config.path))
    log.print("============================================================")
    log.print("")

    log.print("Settings:")
    log.print("  Editor:       " .. tostring(context.config.editor))
    log.print("  Simulate:     " .. tostring(context.config.simulate))
    log.print("")

    log.print("Directories:")

    local pods_path = context.config.pods.path or ""
    local pods_status = "[NOT FOUND]"
    if system.directory_exists(pods_path) then
        pods_status = "[OK]"
    end
    local abs_pods_path = system.get_absolute_path(pods_path)
    log.print(util.format_line(string.format("  %-14s%s", "Pods:", abs_pods_path), pods_status))

    local recipes_path = context.config.recipes.path or ""
    local recipes_status = "[NOT FOUND]"
    local recipes_files = system.list_directory(recipes_path, "%.lua$")
    if system.directory_exists(recipes_path) then
        local count = recipes_files and #recipes_files or 0
        recipes_status = string.format("[OK, %d recipes found]", count)
    end
    local abs_recipes_path = system.get_absolute_path(recipes_path)
    log.print(util.format_line(string.format("  %-14s%s", "Recipes:", abs_recipes_path), recipes_status))
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

    for i, g in ipairs(group_names) do
        log.print("  • " .. g)
        local elements = groups[g]
        for j, el in ipairs(elements) do
            local is_last = (j == #elements)
            local branch = is_last and "└── " or "├── "

            if string.begins_with(el, "@") then
                local subgroup_name = string.sub(el, 2)
                log.print("    " .. branch .. el)

                local sub_elements = groups[subgroup_name]
                if not sub_elements then
                    log.print("    " .. (is_last and "    " or "│   ") .. "└── [MISSING GROUP]")
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
                        log.print(util.format_line(line, status))
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
                log.print(util.format_line(line, status))
            end
        end
        if i < #group_names then
            log.print("    ")
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

---Handle config mode.
---@param context table
local function mode_config__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    if type(context) ~= "table" or type(context.parameters) ~= "table" then
        error("mode_config__handle requires a valid context object", 2)
    end
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

---Print status of containers.
---@param context table
---@param targets table
local function mode_default__status(context, targets)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
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

---Print help for status action.
---@param context table
local function mode_default__status_help(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    log.print("PodScript " .. get_version_string() .. " - Status\n")
    log.print("Display the runtime status of pods and containers.")
    log.print("Usage: pods status [OPTIONS] [TARGETS]")
    log.print("   or: lua pods.lua status [OPTIONS] [TARGETS]\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output")
    log.print("  --all              include all unmanaged podman containers")
    log.print("  --full             display extended container information (image, command, ports)\n")
    log.print("TARGETS:")
    log.print("  *                  names of recipes or groups to filter (defaults to all managed recipes)")
end
---Handle default mode.
---@param context table
local function mode_default__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
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

    local untangled_targets = util.untangle(context, targets)
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

local function mode_logs__help(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    if context.flags.simulate then
        log.print("PodScript " .. get_version_string() .. " - Logs Mode (SIMULATED)\n")
        log.print("Simulate the execution of log commands for a recipe's pod or container.")
        log.print("Usage: pods simulate logs [OPTIONS] [<action>] <recipe>[/container]")
        log.print("   or: lua pods.lua simulate logs [OPTIONS] [<action>] <recipe>[/container]\n")
    else
        log.print("PodScript " .. get_version_string() .. " - Logs Mode\n")
        log.print("Show or follow logs for a recipe's pod or container.")
        log.print("Usage: pods logs [OPTIONS] [<action>] <recipe>[/container]")
        log.print("   or: lua pods.lua logs [OPTIONS] [<action>] <recipe>[/container]\n")
    end
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
    log.print("  --debug            enable debug output\n")
    log.print("TARGET:")
    log.print("  <recipe>             show logs for all containers in the recipe's pod")
    log.print("  <recipe>/<container> filter logs to a specific container (index, relative, absolute)")
end

local function mode_logs__execute(context, action, target)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
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

    if context.flags.simulate then
        log.print("Execute log command: ")
        log.print(command_str .. ";")
        return true
    else
        return os.execute(command_str)
    end
end

local function mode_logs__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
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
--    SECTION Mode Simulate
--
-- ------------------------------------------------------------------------- --

---Handle simulate mode.
---@param context table
local function mode_simulate__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    log.info("Simulate mode is active.")
    context.flags.simulate = true
    local parameters = context.parameters
    if parameters[1] == "command" then
        -- remove "command" from parameters
        context.parameters = table.sub(parameters, 2)
        mode_command__handle(context)
    elseif parameters[1] == "logs" then
        -- remove "logs" from parameters
        context.parameters = table.sub(parameters, 2)
        mode_logs__handle(context)
    else
        mode_default__handle(context)
    end
end
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Help
--
-- ------------------------------------------------------------------------- --

---Handle help mode. Prints help.
---@param context table
local function mode_help__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    log.print("PodScript " .. get_version_string() .. "\n")
    log.print("Usage: pods [MODE] [OPTIONS] ACTION [TARGETS]")
    log.print("   or: lua pods.lua [MODE] [OPTIONS] ACTION [TARGETS]\n")
    log.print("MODES:")
    log.print("  *                  default mode")
    log.print("  command            execute a command defined in a recipe")
    log.print("  config             manage and inspect configuration")
    log.print("  help               display this help and exit")
    log.print("  init               initialize default configuration and recipe")
    log.print("  logs               show or follow logs for a pod or container")
    log.print("  recipe             inspect and edit recipes")
    log.print("  simulate           simulate all commands (default mode)\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output\n")
    log.print("Valid in default and simulate mode only:\n")
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

---Create initial recipe and config files.
---@param context table
local function mode_init__create(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
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

---Print init help.
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

---Handle init mode.
---@param context table
local function mode_init__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
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

---Loads PodScript config. Sets default values if missing.
---Returns false if fails to load a file or no recipes are defined.
---@param context table
---@return boolean
local function main__config_load_and_set(context)
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
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

---Parse arguments and retuns true if error.
---@param context table
---@param arguments string[]
---@param modes table
local function main__parse_arguments(context, arguments, modes)
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    if type(context) ~= "table" then error("context must be a table", 2) end
    if type(arguments) ~= "table" then error("arguments must be a table", 2) end
    if type(modes) ~= "table" then error("modes must be a table", 2) end
    context.config = context.config or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
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

---Main function.
---@param arguments string[]
global function main(arguments)
    local modes = {
        command = mode_command__handle,
        config = mode_config__handle,
        default = mode_default__handle,
        help = mode_help__handle,
        init = mode_init__handle,
        logs = mode_logs__handle,
        recipe = mode_recipe__handle,
        simulate = mode_simulate__handle,
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

    -- config simulate activates simulate mode if default mode is selected
    if context.config.simulate and context.mode == modes.default then
        context.mode = modes.simulate
    end

    -- handle mode
    context.mode(context)
end

-- prevent excecution when imported from test_suite
if arg[0] ~= "test.lua" then
    -- execute main
    main(arg)
end
