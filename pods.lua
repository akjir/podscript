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

    ---Print debug.
    ---@param message string
    debug = function(message)
        log.print("DEBUG: " .. message)
    end,

    ---Print info.
    ---@param message string
    info = function(message)
        log.print("INFO: " .. message)
    end,

    ---Print warning.
    ---@param message string
    warning = function(message)
        log.print("WARNING: " .. message)
    end,

    ---Print error.
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

---Get value from table or default if key not found
---@param table table|nil
---@param key any
---@param default any
table.get_or_default = function(table, key, default)
    if table == nil then return default end
    local value = table[key]
    if value == nil then
        return default
    else
        return value
    end
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
    -- if string.is_nil_or_empty(str) then return "" end -- shouldn't necessary
    return string.lower(str:trim():gsub("%s+", "_"))
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
        local major, minor = _VERSION:match("Lua (%d+)%.(%d+)")
        major = tonumber(major)
        minor = tonumber(minor)

        if major > 5 or (major == 5 and minor >= 4) then
            return true
        end
        return false
    end,

    ---Check if the current operating system is Linux.
    ---@return boolean
    check_os = function()
        local handle = io.popen("uname -s")
        if handle == nil then return false end
        local result = handle:read("*a")
        handle:close()

        -- we need to trim the result, because uname -s returns a newline
        result = string.trim(result)

        return result == "Linux"
    end,

    ---Check if the current Podman version is 5.8.0 or higher.
    ---@return boolean
    check_podman_version = function()
        local handle = io.popen("podman --version 2>&1")
        if handle == nil then return false end
        local result = handle:read("*a")
        handle:close()

        -- podman --version returns something like "podman version 5.8.1"
        local version = result:match("version%s*(%d+%.%d+%.%d+)")
        if not version then return false end

        local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)")
        major = tonumber(major)
        minor = tonumber(minor)
        -- patch is not strictly needed for 5.8.0+, but good to have
        patch = tonumber(patch)

        if major > 5 or (major == 5 and minor >= 8) then
            return true
        end
        return false
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
            -- need better error handling, popen prints directly
            local handle = io.popen(command)
            if handle == nil then return end
            local output = handle:read("*l")
            if output ~= nil then
                log.print(prefix .. output)
            else
                log.print(prefix .. "...")
            end
            handle:close()
        end
    end,

    ---Load a lua file.
    ---@param full_path string
    ---@return table|nil
    ---@return string|nil
    load_lua_file = function(full_path)
        local ok, result = pcall(dofile, full_path)
        if not ok then
            log.error(result)
            return nil, result
        end
        return result, nil
    end
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
    local recipe, _ = system.load_lua_file(full_path)
    if recipe == nil then
        log.error("Couldn't load recipe '" .. full_path .. "'!")
        return nil
    else
        return recipe
    end
end

---Switch correct pod function and test pod values.
---@param recipe table
---@param action string
---@param config table
local function recipe__validate_and_handle(recipe, target, action, config)
    -- test for pod config name
    if string.is_nil_or_empty(recipe.name) then
        log.error("No recipe name in recipe '" .. target .. "' set!")
        return
    else
        recipe.name = string.trim(recipe.name)
    end

    -- test for pod section
    if table.is_nil_or_empty(recipe.pod) then
        log.error("Pod section in recipe '" .. target .. "' not defined! or empty")
        return
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
        log.error("No default registry in recipe '" .. target .. "' set or empty!")
        return
    end

    -- test for valid pod path
    if string.is_nil_or_empty(recipe.pod.path) then
        -- if no pod path set in recipe use default path from config
        if string.is_nil_or_empty(config.pods.path) then
            log.error("No default pod path and pod path in recipe '" .. target .. "' set or empty!")
            return
        else
            -- if pod path not set use default path with pod name as folder name
            local path = build_full_path(config.pods.path, recipe.pod.name, "")
            log.info("No pod path in recipe '" .. target .. "' set. Path '" .. path .. "' used.")
            recipe.pod.path = path
        end
    end

    -- test for container section
    if table.is_nil_or_empty(recipe.containers) then
        log.error("Container section in recipe '" .. target .. "' not defined or empty!")
        return
    end

    -- test if containers are valid
    local pod_name = recipe.pod.name
    for id = 1, #recipe.containers do
        if not container__is_valid(recipe.containers[id], pod_name) then
            return
        end
    end

    -- switch for correct function
    if (action == "update") then
        -- most of the tests above arn't necessary for update
        pod__update(recipe, config.simulate)
        return
    end
    if action == "recreate" then
        pod__recreate(recipe, config.simulate)
        return
    end
    if action == "remove" then
        pod__remove(recipe, config.simulate)
        return
    end
    if action == "create" then
        pod__create(recipe, config.simulate)
        return
    end
end

-- ------------------------------------------------------------------------- --
--
--    SECTION Config
--
-- ------------------------------------------------------------------------- --

---Loads PodScript config. Sets default values if missing.
---Returns nil if fails to load a file or no recipes are defined.
---@param config_full_path string
---@return table|nil
local function config__load_and_set_defaults(config_full_path)
    local config, _ = system.load_lua_file(config_full_path)
    if config == nil then
        log.error("Couldn't load configuration '" .. config_full_path .. "'!")
        return nil
    end

    if config.recipes == nil then
        log.error("No recipes defined in config '" .. config_full_path .. "'!")
        return nil
    else
        if table.is_nil_or_empty(config.recipes.groups) then
            log.error("No recipes groups defined in configuration '" .. config_full_path .. "'!")
            return nil
        end

        -- set default path for recipes or correct them
        if string.is_nil_or_empty(config.recipes.path) then
            config.recipes.path = "./"
        end
    end

    -- simulate default is true
    if config.simulate == nil then
        config.simulate = true
    end

    -- default pod values
    if config.pods == nil then
        config.pods = {}
    end

    -- default pod path
    if config.pods.path == nil then
        config.pods.path = "" -- no path set, pods need to define a path
    end

    return config
end

---Untangles recipe groups. Respects target order.
---First appearance of target stays, duplicates will be removed.
---Returns nil if a group or a recipe is not found.
---@param groups table
---@param targets table
---@return table|nil
local function config__untangle_recipes(groups, targets)
    if debug then
        log.debug("Targets   - " .. table.concat(targets, " "))
    end

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
    if debug then
        log.debug("Untangled - " .. table.concat(untangled, " "))
    end
    return untangled
end

-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Default
--
-- ------------------------------------------------------------------------- --

---Handle default mode.
---@param options table
local function default__handle(options)

end

-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Help
--
-- ------------------------------------------------------------------------- --

---Handle help mode. Prints help.
---@param options table
local function help__handle(options)
    log.print("PODSCRIPT " .. VERSION .. "\n")
    log.print("Usage: pods [MODE] [OPTIONS] ACTION [TARGETS]")
    log.print("   or: lua pods.lua [MODE] [OPTIONS] ACTION [TARGETS]\n")
    log.print("MODES:")
    log.print("  *                  default mode")
    log.print("  help               display this help and exit\n")
    log.print("OPTIONS:")
    log.print("  --config NAME      use config with given name or path")
    log.print("  --simulate         forces simulate mode\n")
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
---@param arguments table
---@param options table
---@param modes table
---@return boolean
local function main__parse_arguments(arguments, options, modes)
    -- no arguments
    -- don't use table__size, it will be 2 (key -1 and 0 are used)
    if #arguments == 0 then
        options.mode = modes["help"]
        return false
    end
    -- parse arguments
    local skip = false
    for i = 1, #arguments do
        local argument = arguments[i]
        if skip == true then -- skips to allow "--argument value"
            skip = false
        else
            -- reset skip if used
            if skip then skip = false end

            if argument == "help" then
                options.mode = modes["help"]
                break -- print help and ignore the rest
            elseif argument == "--simulate" then
                options.simulate = true
            elseif argument == "--config" then
                skip = true
                options.config = table.get_or_default(arguments, i + 1, "")
            else
                if string.begins_with(argument, "--") then
                    log.error("Unknown option '" .. argument .. "'.")

                    return true
                elseif options.action == "" then
                    -- first argument is action
                    options.action = argument
                else
                    -- followed arguments are targets
                    table.insert(options.targets, argument)
                end
            end
        end
    end
    return false
end

---Validate and normalize options. Returns false if error.
---@param options table
---@return boolean
local function main__validate_and_normalize_options(options)
    -- validate action
    if string.is_nil_or_empty(options.action) then
        log.error("No action set.")
        return false
    else
        options.action = normalize_name(options.action)
    end
    if not table.contains({ "create", "recreate", "remove", "update" }, options.action) then
        log.error("Unknown action '" .. options.action .. "'.")
        return false
    end

    -- validate targets
    if table.is_nil_or_empty(options.targets) then
        log.error("No targets set.")
        return false
    end

    -- normalize config name
    if not string.is_nil_or_empty(options.config) then
        options.config = normalize_name(options.config)
    end
    return true
end

---Main function.
---@param arguments string[]
function main(arguments)
    local modes = {
        help = help__handle,
    }

    -- default options
    local options = {
        action = "",       -- action for targets
        config = "config", -- config name to use
        mode = nil,        -- mode to use
        simulate = false,  -- simulate all commands
        targets = {},      -- target recipe names
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

    -- parse arguments
    if main__parse_arguments(arguments, options, modes) then return end

    -- handle mode
    if options.mode ~= nil then
        options.mode(options)
        return
    end

    -- validate options
    if not main__validate_and_normalize_options(options) then return end

    -- parse config
    local config_name = options.config
    local config_full_path = build_full_path(config_name, "", ".lua")
    local config = config__load_and_set_defaults(config_full_path)
    if config == nil then return end

    -- enforce simulate from arguments
    if options.simulate then
        config.simulate = true
    end

    -- print info if simulate mode is active
    if config.simulate == true then
        log.info("Simulate mode is active.")
    end

    -- print info if non default confi is used
    if config_name ~= "config" then
        log.info("Config '" .. config_full_path .. "' is used.")
    end

    -- clean up targets
    local untangled_targets = config__untangle_recipes(config.recipes.groups, options.targets)
    if untangled_targets == nil then return end

    -- handle recipes
    local recipe_path = config.recipes.path
    for i = 1, #untangled_targets do
        local target = untangled_targets[i]
        -- load recipe
        local recipe = recipe__load(recipe_path, target)
        -- handle recipe
        if recipe ~= nil then
            recipe__validate_and_handle(recipe, target, options.action, config)
        end
    end
end

-- prevent excecution when imported from test_suite
if arg[0] ~= "test.lua" then
    -- execute main
    main(arg)
end

