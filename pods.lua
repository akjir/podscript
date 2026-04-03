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
---@diagnostic disable: lowercase-global

-- ------------------------------------------------------------------------- --
--
--
--       PODSCRIPT
--
--
-- ------------------------------------------------------------------------- --

local VERSION <const> = "1.3.0"

-- debug flag
debug = false

-- ------------------------------------------------------------------------- --
--
--    SECTION Log
--
-- ------------------------------------------------------------------------- --

log = {
    -- Proxy to handle output, defaults to standard print
    print = print,

    ---Print debug message if debug is enabled.
    ---@param message string
    debug = function(message)
        if debug then
            log.print("DEBUG: " .. message)
        end
    end,

    ---Print info message.
    ---@param message string
    info = function(message)
        log.print("INFO: " .. message)
    end,

    ---Print warning message.
    ---@param message string
    warning = function(message)
        log.print("WARNING: " .. message)
    end,

    ---Print error message.
    ---@param message string
    error = function(message)
        log.print("ERROR: " .. message)
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
string.begins_with = function(str, prefix)
    return str:sub(1, #prefix) == prefix
end

---Test if a string ends with another string.
---@param str string
---@param suffix string
---@return boolean
string.ends_with = function(str, suffix)
    return str:sub(- #suffix) == suffix
end

---Test if string is empty or nil.
---@param str string|nil
---@return boolean
string.is_nil_or_empty = function(str)
    return str == nil or str == ""
end

---Removes leading and trailing whitespaces.
---@param str string
---@return string
string.trim = function(str)
    -- avoid lazy evaluation of '.-' in str:match("^%s*(.-)%s*$")
    return str:match("^()%s*$") and "" or str:match("^%s*(.*%S)")
end

-- ------------------------------------------------------------------------- --
--
--    SECTION Table
--
-- ------------------------------------------------------------------------- --

---Appends a sequential table to another.
---Example: {1,2,3} and {4,5,6} will be {1,2,3,4,5,6}.
---@param target table|nil
---@param source table|nil
table.append = function(target, source)
    if target == nil then return end
    if source == nil then return end
    table.move(source, 1, #source, #target + 1, target)
end

---Test if a table contains a value. Only works with sequential tables.
---Returns false if table is nil or value is not found.
---@param table table|nil
---@param value any
---@return boolean
table.contains = function(table, value)
    if table == nil then return false end
    for i = 1, #table do
        if (table[i] == value) then return true end
    end
    return false
end

---Remove duplicates from a table. Returns a new table and don't modify the original.
---@param table table
---@return table
table.remove_duplicates = function(table)
    local seen = {}   -- Keeps track of values we've already encountered
    local result = {} -- The new table with unique values
    local index = 1   -- Manual index tracker is faster than table.insert

    for i = 1, #table do
        local value = table[i]
        -- If the value hasn't been added to 'seen' yet...
        if not seen[value] then
            seen[value] = true    -- Mark it as seen
            result[index] = value -- Add it to the result array
            index = index + 1     -- Increment the index
        end
    end

    return result
end

---Get value from table or default if key not found.
---You can use "table and table[key] or default" instead, if there is no false value in table.
---@param table table|nil
---@param key any
---@param default any
table.get_or_default = function(table, key, default)
    if table == nil then return default end
    local value = table[key]
    if value ~= nil then
        return value
    end
    return default
end

---Check if a key exists in a table.
---@param table table|nil
---@param key any
---@return boolean
table.has_key = function(table, key)
    return table ~= nil and table[key] ~= nil
end

---Test if a table is nil or empty.
---@param table table|nil
---@return boolean
table.is_nil_or_empty = function(table)
    return table == nil or next(table) == nil
end

---Merges two tables by adding key-value pairs from one table to another.
---If a key from the source table already exists in the target table, its value will be overwritten.
---@param target table|nil
---@param source table|nil
table.merge = function(target, source)
    if target == nil then return source end
    if source == nil then return target end
    for key, value in pairs(source) do
        target[key] = value
    end
end

---Get table size, including non-numeric keys.
---@param table table
---@return integer
table.size = function(table)
    if table == nil then return 0 end
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- ------------------------------------------------------------------------- --
--
--    SECTION Helper
--
-- ------------------------------------------------------------------------- --

---Build a full path with given parts.
---@param path string
---@param file_name string
---@param file_extension string
---@return string
local function build_full_path(path, file_name, file_extension)
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
---@param str string The input string to be normalized.
---@return string # The fully formatted string (e.g., " My  Name " becomes "my_name").
local function normalize_name(str)
    return string.lower(str:trim():gsub("%s+", "_"))
end

---Parse the action and targets parameters from a registry.
---@param registry table The registry to parse.
---@return string, table # The action and targets.
local function parse_action_and_targets_parameters(registry)
    local parameters = registry.parameters
    local targets = table.move(parameters, 2, #parameters, 1, {})
    return parameters[1] or "", targets
end

---Splits a string by the first equals sign. If no equals sign is found, the value is set to true (as flag is given).
---@param argument string The input string to be split.
---@return string, string|boolean # The key and value.
local function split_argument(argument)
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

system = {
    ---Check if the current Lua version is 5.4 or higher.
    ---@return boolean
    check_lua_version = function()
        local major_string, minor_string = _VERSION:match("Lua (%d+)%.(%d+)")
        if not major_string or not minor_string then return false end
        local major = tonumber(major_string)
        local minor = tonumber(minor_string)
        return major > 5 or (major == 5 and minor >= 4)
    end,

    ---Check if the current operating system is Linux.
    ---@return boolean
    check_os = function()
        local handle = io.popen("uname -s")
        if not handle then return false end
        local result = handle:read("*a")
        handle:close()

        -- we need to trim the result, because uname -s returns a newline
        return "Linux" == string.trim(result)
    end,

    ---Check if the current Podman version is 5.8.0 or higher.
    ---@return boolean
    check_podman_version = function()
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
    end,

    ---Execute a command.
    ---Only executes a command, if simulate is set to false.
    ---@param command string
    ---@param prefix string
    ---@param simulate boolean
    exec = function(command, prefix, simulate)
        if not string.ends_with(command, ";") then
            command = command .. ";"
        end
        if simulate then
            if not string.is_nil_or_empty(prefix) then
                log.print(prefix)
            end
            log.print(command)
        else
            -- combine STDOUT and STDERR using 2>&1
            local handle = io.popen(command .. " 2>&1")
            if not handle then
                log.error("Failed to execute command '" .. command .. "'!")
                return
            end

            local output = handle:read("*a")
            local success, exit_type, exit_code = handle:close()
            if not string.is_nil_or_empty(output) then
                -- include the error message if the command failed
                log.print(prefix .. output:gsub("%s+$", ""))
            else
                log.print(prefix .. "...")
            end

            -- check if the command actually succeeded
            if not success then
                log.error("Command exited with code '" .. tostring(exit_code) .. "'!")
            end
        end
    end,

    ---Loads a Lua file and returns the result.
    ---@param full_path string
    ---@return table|nil result The object returned by the file (usually a table).
    ---@return string|nil error Error message if something went wrong.
    ---@return string|nil error_type The type of error ("load" or "execution").
    load_lua_file = function(full_path)
        local chunk, err = loadfile(full_path)
        if not chunk then
            return nil, err, "load"
        end
        local success, result = pcall(chunk)
        if not success then
            return nil, result, "execution"
        end
        return result, nil, nil
    end,

    ---Read file content line by line and return as a table.
    ---@param full_path string
    ---@return table|nil
    read_file_content_by_line = function(full_path)
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
    end,

    ---Check if the program is run with elevated execution rights (sudo).
    ---@return boolean
    runs_elevated = function()
        local handle = io.popen("id -u")
        if not handle then return false end
        local result = handle:read("*a")
        handle:close()
        return "0" == string.trim(result)
    end,
}

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
    -- main command
    local commands = { "podman run" }

    -- container name
    commands[#commands + 1] = "--name"
    commands[#commands + 1] = container.name

    -- add container to pod
    commands[#commands + 1] = "--pod"
    commands[#commands + 1] = pod.name

    -- detach
    -- default is false
    if container.detach then
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
                        if string.begins_with(host_dir, ".") then
                            host_dir = string.sub(host_dir, 2)
                        end
                        host_dir = build_full_path(pod.path, host_dir, "")
                    end
                    command = host_dir .. ":" .. container_dir
                end
                if not string.is_nil_or_empty(options) then
                    command = command .. ":" .. options
                end
                commands[#commands + 1] = "--volume"
                commands[#commands + 1] = command
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
    commands[#commands + 1] = registry .. "/" .. container.image

    -- commands
    -- see: podman run --detach image:tag command
    if not table.is_nil_or_empty(container.commands) then
        commands[#commands + 1] = table.concat(container.commands, " ")
    end

    -- create and execute final podman command
    system.exec(table.concat(commands, " "), "Create container '" .. container.name .. "': ", simulate)
end

---Ensure container name.
---@param container table
---@param pod_name string
---@param container_alternate_name string
---@return boolean
local function container__ensure_name(container, pod_name, container_alternate_name)
    -- container name is optional
    if string.is_nil_or_empty(container.name) then
        container.name = pod_name .. "-" .. container_alternate_name
    else
        container.name = normalize_name(container.name)
        if string.begins_with(container.name, "*") then
            container.name = pod_name .. "-" .. container.name:sub(2)
        end
    end
    return true
end

---Test if container is valid.
---@param container table
---@param pod_name string
---@return boolean
local function container__is_valid(container, pod_name)
    if table.is_nil_or_empty(container) then
        log.error("A container in pod '" .. pod_name .. "' is empty!")
        return false
    end

    -- container.name is optional, will be set later

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
    system.exec("podman stop " .. container.name, "Stop container '" .. container.name .. "': ", simulate)
    system.exec("podman rm " .. container.name, "Remove container '" .. container.name .. "': ", simulate)
end

---Update a container image.
---@param container table
---@param pod table
---@param simulate boolean
local function container__update(container, pod, simulate)
    local registry = table.get_or_default(container, "registry", pod.registry)
    log.print("Update container '" .. container.name .. "' ...")
    system.exec("podman pull " .. registry .. "/" .. container.image, "", simulate)
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
    local commands = { "podman pod create" }

    -- pod name
    commands[#commands + 1] = "--name"
    commands[#commands + 1] = recipe.pod.name

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
        simulate)

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
    -- remove containers
    local containers = recipe.containers
    for id = #containers, 1, -1 do -- reverse order when shutting down containers
        local container = containers[id]
        container__ensure_name(container, recipe.pod.name, tostring(id))
        container__remove(container, simulate)
    end

    -- remove pod
    system.exec("podman pod rm " .. recipe.pod.name, "Remove pod '" .. recipe.name .. "' ('" .. recipe.pod.name .. "'): ",
        simulate)
end

---Remove and create pod and containers.
---@param recipe table
---@param simulate boolean
local function pod__recreate(recipe, simulate)
    pod__remove(recipe, simulate)
    pod__create(recipe, simulate)
end

---Update containers of the pod.
---@param recipe table
---@param simulate boolean
local function pod__update(recipe, simulate)
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
--    SECTION Recipe
--
-- ------------------------------------------------------------------------- --

---Load PodScript recipe.
---@param recipe_path string
---@param recipe_name string
---@return table|nil
local function recipe__load(recipe_path, recipe_name)
    local full_path = build_full_path(recipe_path, recipe_name, ".lua")
    local recipe, error, _ = system.load_lua_file(full_path)
    if recipe == nil then
        if error ~= nil then
            log.error(error)
        end
        log.error("Couldn't load recipe '" .. full_path .. "'!")
        return nil
    else
        return recipe
    end
end

---Validate recipe.
---@param registry table
---@param recipe table
---@param file_name string
---@return boolean
local function recipe__validate(registry, recipe, file_name)
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
        recipe.pod.name = normalize_name(recipe.name)
    else
        recipe.pod.name = normalize_name(recipe.pod.name)
    end

    -- test for pod registry
    if string.is_nil_or_empty(recipe.pod.registry) then
        log.error("No default registry in recipe '" .. file_name .. "' set or empty!")
        return false
    end

    -- test for valid pod path
    if string.is_nil_or_empty(recipe.pod.path) then
        -- if no pod path set in recipe use default path from config
        if string.is_nil_or_empty(registry.config.pods.path) then
            log.error("No default pod path and pod path in recipe '" .. file_name .. "' set or empty!")
            return false
        else
            -- if pod path not set use default path with pod name as folder name
            local path = build_full_path(registry.config.pods.path, recipe.pod.name, "")
            log.info("No pod path in recipe '" .. file_name .. "' set. Path '" .. path .. "' used.")
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

-- ------------------------------------------------------------------------- --
--
--    SECTION Config
--
-- ------------------------------------------------------------------------- --

---Loads PodScript config. Sets default values if missing.
---Returns false if fails to load a file or no recipes are defined.
---@param registry table
---@param config_full_path string
---@return boolean
local function config__load_and_set(registry, config_full_path)
    local config, error, _ = system.load_lua_file(config_full_path)
    if config == nil then
        if error ~= nil then
            log.error(error)
        end
        log.error("Couldn't load configuration '" .. config_full_path .. "'!")
        return false
    end

    -- config values
    registry.config = config
    registry.config.full_path = config_full_path
    if registry.config.simulate == nil then
        registry.config.simulate = true
    end

    -- pod values
    if not registry.config.pods then
        registry.config.pods = {}
    end
    if not registry.config.pods.path then
        registry.config.pods.path = "" -- no path set, pods need to define a path
    end

    -- recipes values
    registry.recipes = config.recipes
    if table.is_nil_or_empty(registry.recipes) then
        log.error("No recipes defined in config '" .. config_full_path .. "'!")
        return false
    else
        if table.is_nil_or_empty(registry.recipes.groups) then
            log.error("No recipes groups defined in configuration '" .. config_full_path .. "'!")
            return false
        end
        -- set default path for recipes or correct them
        if string.is_nil_or_empty(registry.recipes.path) then
            registry.recipes.path = "."
        end
    end
    return true
end

---Untangles recipe groups. Respects target order.
---First appearance of target stays, duplicates will be removed.
---Returns nil if a group or a recipe is not found.
---@param groups table
---@param targets table
---@return table|nil
local function config__untangle_recipes(groups, targets)
    log.debug("Targets   - " .. table.concat(targets, " "))
    local untangled = {}

    for i = 1, #targets do
        local target = targets[i]

        -- handle group
        if string.begins_with(target, "@") then
            local group_recipes = groups[target:sub(2)] -- remove @ from target

            if group_recipes == nil then
                log.error("Unknown recipe group '" .. target .. "'.")
                return nil
            end

            table.append(untangled, group_recipes)
        else -- handle single target
            local found = nil

            for _, group_targets in pairs(groups) do
                if table.contains(group_targets, target) then
                    found = target
                    break
                end
            end

            if found == nil then
                log.error("Target '" .. target .. "' not found in config.")
                return nil
            else
                table.insert(untangled, found)
            end
        end
    end

    untangled = table.remove_duplicates(untangled)
    log.debug("Untangled - " .. table.concat(untangled, " "))
    return untangled
end

-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Config
--
-- ------------------------------------------------------------------------- --

---Print config help.
local function mode_recipe__help()
    log.print("PODSCRIPT " .. VERSION .. "\n")
    log.print("Usage: pods recipe [OPTIONS] ACTION NAME")
    log.print("   or: lua pods.lua recipe [OPTIONS] ACTION NAME\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path\n")
    log.print("ACTIONS:")
    log.print("  help               display this help and exit")
    log.print("  print              print recipe\n")
    log.print("NAME:")
    log.print("  *                  name of the recipe")
end

---Print recipe content.
---@param registry table
---@param name string
local function mode_recipe__print(registry, name)
    if string.is_nil_or_empty(name) then
        log.error("No recipe name given.")
        return
    end
    local normalized_name = normalize_name(name)
    local found = config__untangle_recipes(registry.config.recipes.groups, { normalized_name })
    -- config__untangle_recipes already logs the error
    if found == nil then return end

    local recipe_path = registry.recipes.path
    local full_path = build_full_path(recipe_path, normalized_name, ".lua")

    local lines = system.read_file_content_by_line(full_path)
    if not lines then return end

    for i = 1, #lines do
        local prefix = string.format("%3d: ", i)
        log.print(prefix .. lines[i])
    end
end

---Handle recipe mode.
---@param registry table
local function mode_recipe__handle(registry)
    log.debug("Recipe mode is used.")
    local action = registry.parameters[1]
    if action == nil then
        log.error("No action given.")
        return
    end
    local name = registry.parameters[2]
    if string.is_nil_or_empty(action) or action == "help" then
        action = "help"
    end
    local actions = {
        help = mode_recipe__help,
        print = mode_recipe__print
    }
    local execute = actions[action] or function(_, _)
        log.error("Unknown action: " .. tostring(action))
    end
    execute(registry, name)
end

-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Config
--
-- ------------------------------------------------------------------------- --

---Print config help.
local function mode_config__help()
    log.print("PODSCRIPT " .. VERSION .. "\n")
    log.print("Usage: pods config [OPTIONS] ACTION")
    log.print("   or: lua pods.lua config [OPTIONS] ACTION\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("ACTIONS:")
    log.print("  help               display this help and exit")
    log.print("  print              print config")
end

---Print config.
---@param registry table
local function mode_config__print(registry)
    local lines = system.read_file_content_by_line(registry.config.full_path)
    if not lines then return end

    for i = 1, #lines do
        local prefix = string.format("%3d: ", i)
        log.print(prefix .. lines[i])
    end
end

---Handle config mode.
---@param registry table
local function mode_config__handle(registry)
    log.debug("Config mode is used.")
    local action, _ = parse_action_and_targets_parameters(registry)
    local actions = {
        help = mode_config__help,
        print = mode_config__print
    }
    local execute = actions[action] or function()
        log.error("Unknown action: " .. tostring(action))
    end
    execute(registry)
end

-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Default
--
-- ------------------------------------------------------------------------- --

---Handle default mode.
---@param registry table
local function mode_default__handle(registry)
    log.debug("Default mode is used.")
    local action, targets = parse_action_and_targets_parameters(registry)

    -- validate action
    if action == "" then
        log.error("No action set.")
        return
    end
    if not table.contains({ "create", "recreate", "remove", "update" }, action) then
        log.error("Unknown action '" .. action .. "'.")
        return
    end

    -- validate targets
    if table.is_nil_or_empty(targets) then
        log.error("No targets set.")
        return
    end

    -- clean up targets
    local untangled_targets = config__untangle_recipes(registry.recipes.groups, targets)
    if untangled_targets == nil then return end

    -- handle recipes
    local recipe_path = registry.recipes.path
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
        if recipe ~= nil and recipe__validate(registry, recipe, target) then
            --- action is valid at this point
            pod_actions[action](recipe, registry.flags.simulate)
        end
    end
end

-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Simulate
--
-- ------------------------------------------------------------------------- --

---Handle simulate mode.
---@param registry table
local function mode_simulate__handle(registry)
    log.debug("Simulate mode is used.")
    log.info("Simulate mode is active.")
    registry.flags.simulate = true
    mode_default__handle(registry)
end

-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Help
--
-- ------------------------------------------------------------------------- --

---Handle help mode. Prints help.
---@param registry table
local function mode_help__handle(registry)
    log.print("PODSCRIPT " .. VERSION .. "\n")
    log.print("Usage: pods [MODE] [OPTIONS] ACTION [TARGETS]")
    log.print("   or: lua pods.lua [MODE] [OPTIONS] ACTION [TARGETS]\n")
    log.print("MODES:")
    log.print("  *                  default mode")
    log.print("  help               display this help and exit")
    log.print("  simulate           simulate all commands (default mode)\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output\n")
    log.print("Valid in default and simulate mode only:\n")
    log.print("ACTIONS:")
    log.print("  create             create a new pod")
    log.print("  recreate           removes and then creates a new pod")
    log.print("  remove             remove a running pod")
    log.print("  update             update all defined images of the pod\n")
    log.print("TARGETS:")
    log.print("  *                  names of recipes or groups defined in a config\n")
    log.print("For more: lua pods.lua [MODE] help")
end

-- ------------------------------------------------------------------------- --
--
--    SECTION Main
--
-- ------------------------------------------------------------------------- --

---Parse arguments and retuns true if error.
---@param registry table
---@param arguments string[]
---@param startup_config table
---@param modes table
local function main__parse_arguments(registry, arguments, startup_config, modes)
    -- no arguments
    -- don't use table__size, it will be 2 (key -1 and 0 are used)
    if #arguments == 0 then
        startup_config.mode_selected = modes.help
        return
    end
    -- parse arguments
    local has_seen_positional = false
    for i = 1, #arguments do
        local argument = arguments[i]
        if string.begins_with(argument, "--") then
            if string.begins_with(argument, "--config=") then
                local _, value = split_argument(argument)
                startup_config.config_path = value
            elseif argument == "--debug" then
                debug = true
            else
                local parameter, value = split_argument(argument)
                registry.flags[parameter] = value
            end
            -- check if argument is a mode
        else
            local is_mode = (not has_seen_positional) and modes[argument]
            has_seen_positional = true
            if is_mode then
                startup_config.mode_selected = modes[argument]
            else
                table.insert(registry.parameters, argument)
            end
        end
    end
end

---Main function.
---@param arguments string[]
function main(arguments)
    local modes = {
        default = mode_default__handle,
        config = mode_config__handle,
        help = mode_help__handle,
        recipe = mode_recipe__handle,
        simulate = mode_simulate__handle,
    }

    local startup_config = {
        config_path = "config",
        mode_selected = modes.default,
    }

    local registry = {
        config = {},
        flags = {},
        parameters = {},
    }

    -- check lua version
    if not system.check_lua_version() then
        log.error("Lua 5.4 or higher is required.")
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
    main__parse_arguments(registry, arguments, startup_config, modes)

    log.debug("Debug mode is enabled.")

    -- normalize config name
    local config_path = startup_config.config_path
    if config_path ~= "config" and config_path ~= "" then
        config_path = normalize_name(config_path)
    end

    -- build full config path
    local config_full_path = build_full_path(config_path, "", ".lua")

    -- print info if non default confi is used and debug is enabled
    if config_path ~= "config" then
        log.debug("Config '" .. config_full_path .. "' is used.")
    end

    -- parse config
    if not config__load_and_set(registry, config_full_path) then
        return
    end

    -- config simulate activates simulate mode if default mode is selected
    if registry.config.simulate and startup_config.mode_selected == modes["default"] then
        startup_config.mode_selected = modes["simulate"]
    end

    -- handle mode
    startup_config.mode_selected(registry)
end

-- prevent excecution when imported from test_suite
if arg[0] ~= "test.lua" then
    -- execute main
    main(arg)
end

