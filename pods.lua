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

---Print help.
local function print_help()
    print("PODSCRIPT " .. VERSION)
    print()
    print("Usage: pods [OPTIONS] ACTION [TARGETS]")
    print("   or: lua pods.lua [OPTIONS] ACTION [TARGETS]")
    print()
    print("ACTION:")
    print("  create             create a new pod")
    print("  recreate           removes and then creates a new pod")
    print("  remove             remove a running pod")
    print("  update             update all defined images of the pod")
    print()
    print("TARGETS:")
    print("  *                  names of recipes or groups defined in a config")
    print()
    print("OPTIONS:")
    print("  --config [NAME]    use config with given name")
    print("  --help             display this help and exit")
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
function string__begins_with(str, prefix)
    return str:sub(1, #prefix) == prefix
end

---Test if a string ends with another string.
---@param str string
---@param suffix string
---@return boolean
function string__ends_with(str, suffix)
    return str:sub(- #suffix) == suffix
end

---Test if string is empty or nil.
---@param str string
---@return boolean
function string__is_nil_or_empty(str)
    return str == nil or str == ""
end

-- not tested, maybe for future use
-- local function string__trim(str)
--     return str:gsub("%s+", "")
--- end

-- ------------------------------------------------------------------------- --
--
--
--         SECTION Table
--
--
-- ------------------------------------------------------------------------- --

---Appends a sequential table to another.
---Example: {1,2,3} and {4,5,6} will be {1,2,3,4,5,6}.
---@param target table
---@param source table
---@return table
function table__append(target, source)
    if source == nil then return target end
    for _, v in ipairs(source) do
        table.insert(target, v)
    end
    return target
end

---Test if a table contains a value. Returns false if is nil.
---@param table table
---@param value any
---@return boolean
local function table__contains(table, value)
    if table == nil then return false end
    for i = 1, #table do
        if (table[i] == value) then return true end
    end
    return false
end

---Get value from table or default if key not found
---@param table table
---@param key any
---@param default any
function table__get_or_default(table, key, default)
    if table == nil then return default end
    local value = table[key]
    if value == nil then
        return default
    else
        return value
    end
end

---Test if a table is nil or empty.
---@param table table
---@return boolean
function table__is_nil_or_empty(table)
    return table == nil or next(table) == nil
end

---Merges two tables by adding key-value pairs from one table to another.
---If a key from the source table already exists in the target table, its value will be overwritten.
---@param target table 
---@param source table
---@return table
function table__merge(target, source)
    if source == nil then return target end
    for key, value in pairs(source) do
        target[key] = value
    end
    return target
end

---Get table size.
---@param table table
---@return integer
function table__size(table)
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- ------------------------------------------------------------------------- --
--
--
--         SECTION Helper
--
--
-- ------------------------------------------------------------------------- --

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

---Build a full path with given parts.
---@param path string
---@param file_name string
---@param file_extension string
---@return string
local function build_full_path(path, file_name, file_extension)
    if string__ends_with(path, "/") or string__begins_with(file_name, "/") then
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
    if not string__ends_with(command, ";") then
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

-- ------------------------------------------------------------------------- --
--
--
--         SECTION Container
--
--
-- ------------------------------------------------------------------------- --

---Validate container values.
---@param container table
---@param pod_name string
---@param container_alternate_name string
---@return boolean
local function container__validate(container, pod_name, container_alternate_name)
    -- test for container image
    if string__is_nil_or_empty(container.image) then
        print_error("Image not set for container '" .. container.name .. "'!")
        return false
    end
    -- test for container name
    -- container name is optional
    if string__is_nil_or_empty(container.name) then
        container.name = pod_name .. "-" .. container_alternate_name
    end
    return true
end

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
    if not string__is_nil_or_empty(container.restart) then
        commands[#commands + 1] = "--restart"
        commands[#commands + 1] = container.restart
    end

    -- container volumes
    if (container.volumes ~= nil) then
        for i = 1, #container.volumes do
            local host_dir = container.volumes[i][1]
            local container_dir = container.volumes[i][2]
            local options = container.volumes[i][3]
            if string__is_nil_or_empty(host_dir) then
                print_error("Host dir cannot be empty! (" .. container.name .. ")")
            else
                -- we check nil and empty but not if it's a valid path
                if string__is_nil_or_empty(container_dir) then
                    print_error("Container dir cannot be empty! (" .. container.name .. ")")
                else
                    -- at this point we know that we have a valid path
                    -- but want to check if there is a separate path wanted
                    -- we don't check this earlier so no default or pod path will still be an error
                    if not string__begins_with(host_dir, "/") then
                        host_dir = build_full_path(pod.path, host_dir, "")
                    end
                    local command = host_dir .. ":" .. container_dir
                    if not string__is_nil_or_empty(options) then
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
    local registry = table__get_or_default(container, "registry", pod.registry)
    commands[#commands + 1] = registry .. "/" .. container.image

    -- commands
    -- see: podman run --detach image:tag command
    if container.commands ~= nil and table__size(container.commands) > 0 then
        commands[#commands + 1] = table.concat(container.commands, " ")
    end

    -- create and execute final podman command
    exec(table.concat(commands, " "), simulate)
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
---@param pod_config table
---@param simulate boolean
local function pod__create(pod_config, simulate)
    print_internal("Create pod '" .. pod_config.name .. "' ...")
    local commands = { "podman pod create" }

    -- pod name
    commands[#commands + 1] = "--name"
    commands[#commands + 1] = pod_config.pod.name

    -- pod publish
    if pod_config.pod.publish ~= nil then
        local publish = pod_config.pod.publish
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
    if pod_config.pod.options ~= nil then
        commands[#commands + 1] = table.concat(pod_config.pod.options, " ")
    end

    -- create pod
    exec(table.concat(commands, " "), simulate)

    -- create containers
    local containers = pod_config.containers
    for id = 1, #containers do
        local container_value_name = containers[id]
        local container = pod_config.container[container_value_name]
        if container__validate(container, pod_config.pod.name, container_value_name) then
            container__create(container, pod_config.pod, simulate)
        end
    end
end

---Remove pod and containers.
---@param pod_config table
---@param simulate boolean
local function pod__remove(pod_config, simulate)
    print_internal("Remove pod '" .. pod_config.name .. "' ...")
    -- remove containers
    local containers = pod_config.containers
    for id = #containers, 1, -1 do -- reverse order when shutting down containers
        local container = pod_config.container[containers[id]]
        if container__validate(container, pod_config.pod.name, containers[id]) then
            container__remove(container, simulate)
        end
    end
    -- remove pod
    exec("podman pod rm " .. pod_config.pod.name, simulate)
end

---Remove and create pod and containers.
---@param pod_config table
---@param simulate boolean
local function pod__recreate(pod_config, simulate)
    pod__remove(pod_config, simulate)
    pod__create(pod_config, simulate)
end

---Update containers of the pod.
---@param pod_config table
---@param simulate boolean
local function pod__update(pod_config, simulate)
    print_internal("Update pod '" .. pod_config.name .. "' ...")
    local containers = pod_config.containers
    -- update containers
    for id = 1, #containers do
        local container = pod_config.container[containers[id]]
        if container__validate(container, pod_config.pod.name, containers[id]) then
            container__update(container, pod_config.pod, simulate)
        end
    end
end

-- ------------------------------------------------------------------------- --
--
--
--         SECTION Recipe
--
--
-- ------------------------------------------------------------------------- --

---Set path to default for PodScript recipes if not defined in config.
---@param recipes table
---@return string
local function recipe__ensure_path(recipes)
    -- at this point recipes should be valid
    local recipe_path = recipes.path
    if not string__is_nil_or_empty(recipe_path) then
        return recipe_path
    else
        return "."
    end
end

---Load PodScript recipe.
---@param recipe_path string
---@param recipe_name string
---@return table|nil
local function recipe__load(recipe_path, recipe_name)
    local full_path = build_full_path(recipe_path, recipe_name, ".lua")
    local recipe, err = load_lua_file(full_path)
    if err then print_error(err) end
    if recipe == nil then
        print_error("Couldn't load PodConfig '" .. recipe_name .. "'! (" .. full_path .. ")")
    end
    return recipe
end

---Switch correct pod function and test pod values.
---@param pod_config table
---@param action string
---@param config table
local function recipe__validate_and_handle(pod_config, target, action, config)
    -- test for pod config name
    if string__is_nil_or_empty(pod_config.name) then
        print_error("No PodConfig name in config '" .. target .. "' set!")
        return
    end
    -- test for pod section
    if pod_config.pod == nil then
        print_error("No pod section in config '" .. target .. "' defined!")
        return
    end
    -- test for pod registry
    if string__is_nil_or_empty(pod_config.pod.registry) then
        print_error("No pod registry in config '" .. target .. "' set!")
        return
    end
    -- test for valid pod path
    if pod_config.pod.path == nil or pod_config.pod.path == "" then
        if config.pods.path == "" then
            print_error("No pod path or default pod path in '" .. target .. "' set!")
            return
        else
            -- if pod path not set use default path with name from PodConfig as folder name
            pod_config.pod.path = config.pods.path .. "/" .. pod_config.name
        end
    end
    -- test for pod name
    -- pod name is optional
    if string__is_nil_or_empty(pod_config.pod.name) then
        pod_config.pod.name = "pod-" .. pod_config.name
    end

    -- switch for correct function
    if (action == "update") then
        pod__update(pod_config, config.simulate)
        return
    end
    if action == "recreate" then
        pod__recreate(pod_config, config.simulate)
        return
    end
    if action == "remove" then
        pod__remove(pod_config, config.simulate)
        return
    end
    if action == "create" then
        pod__create(pod_config, config.simulate)
        return
    end
end

---Loads and handle single PodScript recipe.
---@param config table
---@param target string
---@param action string
local function recipe__handle_single(config, target, action)
    -- assert recipe name
    local recipe_name = ""
    if config.configs.cluster ~= nil then
        if table__contains(config.configs.cluster, target) then
            recipe_name = target
        end
    end
    if config.configs.single ~= nil then
        if table__contains(config.configs.single, target) then
            recipe_name = target
        end
    end
    if recipe_name == "" then
        print_error("PodConfig '" .. target .. "' not defined in config!")
        return
    end
    -- load recipe
    local pod_config_path = recipe__ensure_path(config)
    local pod_config = recipe__load(pod_config_path, recipe_name)
    -- handle recipe
    if pod_config ~= nil then
        recipe__validate_and_handle(pod_config, target, action, config)
    end
end

---Load and handle all PodScript recipes in a cluster.
---@param config table
---@param action string
local function recipe__handle_all(config, action)
    local cluster = config.configs.cluster
    if cluster == nil or table__size(cluster) == 0 then
        print_error("No PodConfig names defined in config under cluster.")
        return
    end
    local recipe_path = recipe__ensure_path(config)
    for i = 1, #cluster do
        -- load recipe
        local pod_config = recipe__load(recipe_path, cluster[i])
        -- handle recipe
        if pod_config ~= nil then
            recipe__validate_and_handle(pod_config, cluster[i], action, config)
        end
    end
end

-- ------------------------------------------------------------------------- --
--
--
--         SECTION Config
--
--
-- ------------------------------------------------------------------------- --

---Load and test podscript config.
---@param config_name string
---@return table|nil
local function config__load_and_validate(config_name)
    if not string__ends_with(config_name, ".lua") then
        config_name = config_name .. ".lua"
    end
    local config, err = load_lua_file(config_name)
    if config == nil then
        if err then print_error(err) end
        print_error("Could not load '" .. config_name .. "'!")
        return nil
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
    local skip = false       -- bad way to do it, but works
    for i = 1, #arguments do
        if skip == true then -- skips the next argument to allow "--option value"
            skip = false
        else
            if arguments[i] == "--help" then
                options.help = true
                break
            elseif arguments[i] == "--config" then
                skip = true
                local config_name = arguments[i + 1]
                if config_name == nil or config_name == "" or string__begins_with(config_name, "--") then
                    print_warning("Config name invalid or not defined.")
                else
                    print_info("Config '" .. config_name .. "' is used.")
                    options.config = config_name
                end
            else
                if string__begins_with(arguments[i], "--") then
                    print_error("Unknown option '" .. arguments[i] .. "'.")
                    return true
                elseif options.action == "" then
                    -- first argument is action
                    options.action = arguments[i]
                elseif options.target == "" then
                    -- second argument is target
                    options.target = arguments[i]
                else
                    print_error("Too many arguments.")
                    return true
                end
            end
        end
    end
    return false
end

---Validate options.
---@param options table
---@return boolean
local function main__validate_options(options)
    -- validate action
    if options.action == nil or options.action == "" then
        print_error("No action set.")
        return false
    end
    if not table__contains({ "create", "recreate", "remove", "update" }, options.action) then
        print_error("Unknown action '" .. options.action .. "'.")
        return false
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
    if main__validate_options(options) then return end

    -- parse config
    local config_name = options.config
    local config = config__load_and_validate(config_name)
    if config == nil then return end

    -- assert recipes
    if table__is_nil_or_empty(config.recipes) then
        print_error("No recipes defined in config!")
        return
    end

    -- print info for active simulate
    if config.simulate then
        print_info("Simulate mode is active.")
    end

    -- handle
    if options.target == "all" then
        recipe__handle_all(config, options.action)
    else
        recipe__handle_single(config, options.target, options.action)
    end
end

-- prevent excecution when imported from test_suite
if arg[0] ~= "test_suite.lua" then
    -- initalize print_internal
    print_internal = print
    -- execute main
    main(arg)
end
