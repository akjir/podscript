---@diagnostic disable: lowercase-global
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

-- ------------------------------------------------------------------------- --
--
--
--       PODSCRIPT
--
--
-- ------------------------------------------------------------------------- --

local VERSION <const> = "1.2.0"

-- ------------------------------------------------------------------------- --
--
--
--         SECTION Print
--
--
-- ------------------------------------------------------------------------- --

-- global hook to handle output
print_internal = nil

-- debug flag
debug = false

---Print help.
local function print_help()
    print_internal("PODSCRIPT " .. VERSION)
    print_internal("")
    print_internal("Usage: pods [OPTIONS] ACTION [TARGETS]")
    print_internal("   or: lua pods.lua [OPTIONS] ACTION [TARGETS]")
    print_internal("")
    print_internal("ACTION:")
    print_internal("  create             create a new pod")
    print_internal("  recreate           removes and then creates a new pod")
    print_internal("  remove             remove a running pod")
    print_internal("  update             update all defined images of the pod")
    print_internal("")
    print_internal("TARGETS:")
    print_internal("  *                  names of recipes or groups defined in a config")
    print_internal("")
    print_internal("OPTIONS:")
    print_internal("  --config [NAME]    use config with given name or path")
    print_internal("  --help             display this help and exit")
    print_internal("  --simulate         forces simulate mode")
end

---Print debug.
---@param message string
local function print_debug(message)
    print_internal("DEBUG: " .. message)
end

---Print info.
---@param message string
local function print_info(message)
    print_internal("INFO: " .. message)
end

---Print warning.
---@param message string
local function print_warning(message)
    print_internal("WARNING: " .. message)
end

---Print error.
---@param message string
local function print_error(message)
    print_internal("ERROR: " .. message)
end

-- ------------------------------------------------------------------------- --
--
--
--         SECTION String
--
--
-- ------------------------------------------------------------------------- --

---Test if a string begins with another string.
---@param str string
---@param prefix string
---@return boolean
local function string__begins_with(str, prefix)
    return str:sub(1, #prefix) == prefix
end

---Test if a string ends with another string.
---@param str string
---@param suffix string
---@return boolean
local function string__ends_with(str, suffix)
    return str:sub(- #suffix) == suffix
end

---Test if string is empty or nil.
---@param str string|nil
---@return boolean
local function string__is_nil_or_empty(str)
    return str == nil or str == ""
end

---Removes leading and trailing whitespaces.
---@param str string
---@return string
local function string__trim(str)
    -- avoid lazy evaluation of '.-' in str:match("^%s*(.-)%s*$")
    return str:match("^()%s*$") and "" or str:match("^%s*(.*%S)")
end

-- add table helper functions to global table object
string.begins_with = string__begins_with
string.ends_with = string__ends_with
string.is_nil_or_empty = string__is_nil_or_empty
string.trim = string__trim

-- ------------------------------------------------------------------------- --
--
--
--         SECTION Table
--
--
-- ------------------------------------------------------------------------- --

---Appends a sequential table to another.
---Example: {1,2,3} and {4,5,6} will be {1,2,3,4,5,6}.
---@param target table|nil
---@param source table|nil
local function table__append(target, source)
    if target == nil then return end
    if source == nil then return end
    table.move(source, 1, #source, #target + 1, target)
end

---Test if a table contains a value. Only works with sequential tables.
---Returns false if table is nil or value is not found.
---@param table table|nil
---@param value any
---@return boolean
local function table__contains(table, value)
    if table == nil then return false end
    for i = 1, #table do
        if (table[i] == value) then return true end
    end
    return false
end

---Remove duplicates from a table. Returns a new table and don't modify the original.
---@param table table
---@return table
local function table__remove_duplicates(table)
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
local function table__get_or_default(table, key, default)
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
local function table__is_nil_or_empty(table)
    return table == nil or next(table) == nil
end

---Merges two tables by adding key-value pairs from one table to another.
---If a key from the source table already exists in the target table, its value will be overwritten.
---@param target table|nil
---@param source table|nil
local function table__merge(target, source)
    if target == nil then return source end
    if source == nil then return target end
    for key, value in pairs(source) do
        target[key] = value
    end
end

---Get table size, including non-numeric keys.
---@param table table
---@return integer
local function table__size(table)
    if table == nil then return 0 end
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- add table helper functions to global table object
table.append = table__append
table.contains = table__contains
table.remove_duplicates = table__remove_duplicates
table.get_or_default = table__get_or_default
table.is_nil_or_empty = table__is_nil_or_empty
table.merge = table__merge
table.size = table__size

-- ------------------------------------------------------------------------- --
--
--
--         SECTION Helper
--
--
-- ------------------------------------------------------------------------- --

---Build a full path with given parts.
---@param path string
---@param file_name string
---@param file_extension string
---@return string
local function build_full_path(path, file_name, file_extension)
    if not string.begins_with(path, "/") and
        not string.begins_with(path, "./")
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

---Execute a command.
---Only executes a command, if simulate is set to false.
---@param command string
---@param simulate boolean
local function exec(command, simulate)
    if not string.ends_with(command, ";") then
        command = command .. ";"
    end
    if simulate then
        print_internal(command)
    else
        local handle = io.popen(command)
        if handle == nil then return end
        print_internal(handle:read("*l"))
        handle:close()
    end
end

---Normalizes a string by trimming outer whitespace, replacing internal spaces with underscores, and converting to lowercase.
---@param str string The input string to be normalized.
---@return string # The fully formatted string (e.g., " My  Name " becomes "my_name").
local function normalize_name(str)
    -- if string.is_nil_or_empty(str) then return "" end -- shouldn't necessary
    return string.lower(str:trim():gsub("%s", "_"))
end

---Load a lua file.
---@param full_path string
---@return table|nil
---@return string|nil
local function load_lua_file(full_path)
    local ok, result = pcall(dofile, full_path)
    if not ok then
        return nil, result
    end
    return result, nil
end

-- ------------------------------------------------------------------------- --
--
--
--         SECTION Container
--
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
    if (container.volumes ~= nil) then
        for i = 1, #container.volumes do
            local host_dir = container.volumes[i][1]
            local container_dir = container.volumes[i][2]
            local options = container.volumes[i][3]
            if string.is_nil_or_empty(host_dir) then
                print_error("Host dir cannot be empty! (" .. container.name .. ")")
            else
                -- we checINFO: No pod path in recipe 'recipe_005_no_path' set. Path '/pods/nopathpod' used.k nil and empty but not if it's a valid path
                if string.is_nil_or_empty(container_dir) then
                    print_error("Container dir cannot be empty! (" .. container.name .. ")")
                else
                    -- at this point we know that we have a valid path
                    -- but want to check if there is a separate path wanted
                    -- we don't check this earlier so no default or pod path will still be an error
                    if not string.begins_with(host_dir, "/") then
                        host_dir = build_full_path(pod.path, host_dir, "")
                    end
                    local command = host_dir .. ":" .. container_dir
                    if not string.is_nil_or_empty(options) then
                        command = command .. ":" .. options
                    end
                    commands[#commands + 1] = "--volume"
                    commands[#commands + 1] = command
                end
            end
        end
    end

    -- container options
    -- if not supported by pods, add them directly to the podman run command
    if container.options ~= nil and table__size(container.options) > 0 then
        commands[#commands + 1] = table.concat(container.options, " ")
    end

    -- container image
    local registry = table.get_or_default(container, "registry", pod.registry)
    commands[#commands + 1] = registry .. "/" .. container.image

    -- commands
    -- see: podman run --detach image:tag command
    if container.commands ~= nil and table.size(container.commands) > 0 then
        commands[#commands + 1] = table.concat(container.commands, " ")
    end

    -- create and execute final podman command
    exec(table.concat(commands, " "), simulate)
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
    end
    return true
end

---Test if container is valid.
---@param container table
---@param pod_name string
---@return boolean
local function container__is_valid(container, pod_name)
    if table.is_nil_or_empty(container) then
        print_error("A container in pod '" .. pod_name .. "' is empty!")
        return false
    end

    -- container.name is optional, will be set later

    -- test for container image
    if string.is_nil_or_empty(container.image) then
        print_error("Image not set for container '" .. container.name .. "'!")
        return false
    end

    return true
end

---Stop and removes a container.
---@param container table
---@param simulate boolean
local function container__remove(container, simulate)
    exec("podman stop " .. container.name, simulate)
    exec("podman rm " .. container.name, simulate)
end

---Update a container image.
---@param container table
---@param pod table
---@param simulate boolean
local function container__update(container, pod, simulate)
    local registry = table__get_or_default(container, "registry", pod.registry)
    exec("podman pull " .. registry .. "/" .. container.image, simulate)
end

-- ------------------------------------------------------------------------- --
--
--
--         SECTION Pod
--
--
-- ------------------------------------------------------------------------- --

---Create pod and containers.
---@param recipe table
---@param simulate boolean
local function pod__create(recipe, simulate)
    print_internal("Create pod '" .. recipe.name .. "' ...")
    local commands = { "podman pod create" }

    -- pod name
    commands[#commands + 1] = "--name"
    commands[#commands + 1] = recipe.pod.name

    -- pod publish
    if recipe.pod.publish ~= nil then
        local publish = recipe.pod.publish
        for _, entry in pairs(publish) do
            local size = table__size(entry)
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
    exec(table.concat(commands, " "), simulate)

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
    print_internal("Remove pod '" .. recipe.name .. "' ...")

    -- remove containers
    local containers = recipe.containers
    for id = #containers, 1, -1 do -- reverse order when shutting down containers
        local container = containers[id]
        container__ensure_name(container, recipe.pod.name, tostring(id))
        container__remove(container, simulate)
    end

    -- remove pod
    exec("podman pod rm " .. recipe.pod.name, simulate)
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
    print_internal("Update pod '" .. recipe.name .. "' ...")
    local containers = recipe.containers

    -- update containers
    for id = 1, #containers do
        container__update(containers[id], recipe.pod, simulate)
    end
end

-- ------------------------------------------------------------------------- --
--
--
--         SECTION Recipe
--
--
-- ------------------------------------------------------------------------- --

---Load PodScript recipe.
---@param recipe_path string
---@param recipe_name string
---@return table|nil
local function recipe__load(recipe_path, recipe_name)
    local full_path = build_full_path(recipe_path, recipe_name, ".lua")
    local recipe, _ = load_lua_file(full_path)
    if recipe == nil then
        print_error("Couldn't load recipe '" .. full_path .. "'!")
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
        print_error("No recipe name in recipe '" .. target .. "' set!")
        return
    else
        recipe.name = string.trim(recipe.name)
    end

    -- test for pod section
    if table.is_nil_or_empty(recipe.pod) then
        print_error("Pod section in recipe '" .. target .. "' not defined! or empty")
        return
    end

    -- test for pod name
    -- pod name is optional
    if string.is_nil_or_empty(recipe.pod.name) then
        recipe.pod.name = "pod-" .. normalize_name(recipe.name)
    else
        recipe.pod.name = normalize_name(recipe.pod.name)
    end

    -- test for pod registry
    if string.is_nil_or_empty(recipe.pod.registry) then
        print_error("No default registry in recipe '" .. target .. "' set or empty!")
        return
    end

    -- test for valid pod path
    if string.is_nil_or_empty(recipe.pod.path) then
        if string.is_nil_or_empty(config.pods.path) then
            print_error("No default pod path and pod path in recipe '" .. target .. "' set or empty!")
            return
        else
            -- if pod path not set use default path with normalized name from config as folder name
            local normalized_name = normalize_name(recipe.name)
            local path = build_full_path(config.pods.path, normalized_name, "")
            print_info("No pod path in recipe '" .. target .. "' set. Path '" .. path .. "' used.")
            recipe.pod.path = path
        end
    end

    -- test for container section
    if table.is_nil_or_empty(recipe.containers) then
        print_error("Container section in recipe '" .. target .. "' not defined or empty!")
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
--
--         SECTION Config
--
--
-- ------------------------------------------------------------------------- --

---Loads PodScript config. Sets default values if missing.
---Returns nil if fails to load a file or no recipes are defined.
---@param config_full_path string
---@return table|nil
local function config__load_and_set_defaults(config_full_path)
    local config, _ = load_lua_file(config_full_path)
    if config == nil then
        print_error("Couldn't load Config '" .. config_full_path .. "'!")
        return nil
    end

    if config.recipes == nil then
        print_error("No recipes defined in config '" .. config_full_path .. "'!")
        return nil
    else
        if table.is_nil_or_empty(config.recipes.groups) then
            print_error("No recipes groups defined in config '" .. config_full_path .. "'!")
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
        print_debug("Targets   - " .. table.concat(targets, " "))
    end

    local untangled = {}
    for i = 1, #targets do
        local target = targets[i]

        -- handle group
        if string.begins_with(target, "@") then
            local group_recipes = groups[target:sub(2)] -- remove @ from target

            if group_recipes == nil then
                print_error("Unknown recipe group '" .. target .. "'.")
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
                print_error("Target '" .. target .. "' not found in config.")
                return nil
            else
                table.insert(untangled, found)
            end
        end
    end

    untangled = table.remove_duplicates(untangled)
    if debug then
        print_debug("Untangled - " .. table.concat(untangled, " "))
    end
    return untangled
end

-- ------------------------------------------------------------------------- --
--
--
--         SECTION Main
--
--
-- ------------------------------------------------------------------------- --

---Parse arguments and retuns true if error.
---@param arguments table
---@param options table
---@return boolean
local function main__parse_arguments(arguments, options)
    -- no arguments
    -- don't use table__size, it will be 2 (key -1 and 0 are used)
    if #arguments == 0 then
        options.help = true
        return false
    end
    -- parse arguments
    local skip = false
    for i = 1, #arguments do
        if skip == true then -- skips to allow "--argument value"
            skip = false
        else
            -- reset skip if used
            if skip then skip = false end

            if arguments[i] == "--help" then
                options.help = true
                break -- print help and ignore the rest
            elseif arguments[i] == "--simulate" then
                options.simulate = true
            elseif arguments[i] == "--config" then
                skip = true
                options.config = table.get_or_default(arguments, i + 1, "")
            else
                if string.begins_with(arguments[i], "--") then
                    print_error("Unknown option '" .. arguments[i] .. "'.")
                    return true
                elseif options.action == "" then
                    -- first argument is action
                    options.action = arguments[i]
                else
                    -- followed arguments are targets
                    table.insert(options.targets, arguments[i])
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
        print_error("No action set.")
        return false
    else
        options.action = normalize_name(options.action)
    end
    if not table.contains({ "create", "recreate", "remove", "update" }, options.action) then
        print_error("Unknown action '" .. options.action .. "'.")
        return false
    end

    -- validate targets
    if table.is_nil_or_empty(options.targets) then
        print_error("No targets set.")
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
    -- default options
    local options = {
        action = "",       -- action for targets
        config = "config", -- config name to use
        help = false,      -- print help
        simulate = false,  -- simulate all commands
        targets = {},      -- target recipe names
    }

    -- parse arguments
    if main__parse_arguments(arguments, options) then return end

    -- print help
    if (options.help) then
        print_help()
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
        print_info("Simulate mode is active.")
    end

    -- print info if non default confi is used
    if config_name ~= "config" then
        print_info("Config '" .. config_full_path .. "' is used.")
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
if arg[0] ~= "test_suite.lua" then
    -- initalize print_internal
    print_internal = print
    -- execute main
    main(arg)
end
