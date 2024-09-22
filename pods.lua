--[[

PodScript
Copyright (C) 2024  Stefan Stark

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
--   PODSCRIPT
-- ------------------------------------------------------------------------- --

local VERSION <const> = "1.0.0"

-- ------------------------------------------------------------------------- --
--      Print
-- ------------------------------------------------------------------------- --

---Print help.
local function print_help()
    print("PODSCRIPT " .. VERSION)
    print()
    print("Usage: pods [OPTIONS] ACTION TARGET")
    print("   or: lua pods.lua [OPTIONS] ACTION TARGET")
    print()
    print("ACTION:")
    print("  create     create a new pod")
    print("  recreate   removes and then creates a new pod")
    print("  remove     remove a running pod")
    print("  update     update all defined images of the pod")
    print()
    print("TARGET:")
    print("  *          name of a valid pod config")
    print("  all        names of valid pod configs defined at a config")
    print()
    print("OPTIONS:")
    print("  --help     display this help and exit")
    print("  --test     use alternative test config")
end

---Print info.
---@param message string
local function print_info(message)
    print("INFO: " .. message)
end

---Print warning.
---@param message string
local function print_warning(message)
    print("WARNING: " .. message)
end

---Print error.
---@param message string
local function print_error(message)
    print("ERROR: " .. message)
end

-- ------------------------------------------------------------------------- --
--      Helper
-- ------------------------------------------------------------------------- --

---Load a lua file.
---@param full_path string
---@return table|nil
---@return string|nil
local function load_lua_file(full_path)
    local ok, error = pcall(dofile, full_path)
    if not ok then
        return nil, error
    end
    return dofile(full_path), nil
end

---Test if a string begins with another string.
---@param str string
---@paran prefix string
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
---@param str string
---@return boolean
local function string__is_nil_or_empty(str)
    return str == nil or str == ""
end

-- not tested, maybe for future use
-- local function string__trim(str)
--     return str:gsub("%s+", "")
--- end

---Test if a table contains a value.
---@param table table
---@param value any
---@return boolean
local function table__contains(table, value)
    for i = 1, #table do
        if (table[i] == value) then return true end
    end
    return false
end

---Get table size.
---@param table table
---@return integer
local function table__size(table)
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
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
---@param command string
---@param dryrun boolean
local function exec(command, dryrun)
    if not string__ends_with(command, ";") then
        command = command .. ";"
    end
    if dryrun then
        print(command)
    else
        local handle = io.popen(command)
        if handle == nil then return end
        print(handle:read("*l"))
        handle:close()
    end
end

-- ------------------------------------------------------------------------- --
--      Container Handling
-- ------------------------------------------------------------------------- --

---Validate container values.
---@param container table
---@param pod_name string
---@param container_id string
---@return boolean
local function container__validate(container, pod_name, container_id)
    -- test for container image
    if string__is_nil_or_empty(container.image) then
        print_error("Image not set for container '" .. container.name .. "'!")
        return false
    end
    -- test for container name
    -- container name is optional
    if string__is_nil_or_empty(container.name) then
        container.name = pod_name .. "-" .. container_id
    end
    return true
end

---Create a container.
---@param container table
---@param pod table
---@param config table
local function container__create(container, pod, config)
    -- main command
    local commands = { "podman run" }
    -- container name
    commands[#commands + 1] = "--name"
    commands[#commands + 1] = container.name
    -- pod name
    commands[#commands + 1] = "--pod"
    commands[#commands + 1] = pod.name
    -- detach
    if container.detach then
        commands[#commands + 1] = "--detach"
    end
    -- container restart
    if not string__is_nil_or_empty(container.restart) then
        commands[#commands + 1] = "--restart"
        commands[#commands + 1] = container.restart
    end
    -- container commands
    -- commands can be uncomment for single or special use
    if container.commands ~= nil and table__size(container.commands) > 0 then
        commands[#commands + 1] = table.concat(container.commands, " ")
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
    -- container image
    commands[#commands + 1] = pod.registry .. "/" .. container.image
    exec(table.concat(commands, " "), config.dryrun)
end

---Stop and removes a container.
---@param container table
---@param config table
local function container__remove(container, config)
    exec("podman stop " .. container.name, config.dryrun)
    exec("podman rm " .. container.name, config.dryrun)
end

---Update a container image.
---@param container table
---@param pod table
---@param config table
local function container__update(container, pod, config)
    exec("podman pull " .. pod.registry .. "/" .. container.image, config.dryrun)
end

-- ------------------------------------------------------------------------- --
--      Pod Handling
-- ------------------------------------------------------------------------- --

---Create pod and containers.
---@param pod_config table
---@param config table
local function pod__create(pod_config, config)
    print("Create pod '" .. pod_config.name .. "' ...")
    local commands = { "podman pod create" }
    -- pod name
    commands[#commands + 1] = "--name"
    commands[#commands + 1] = pod_config.pod.name
    -- pod commands
    if pod_config.pod.commands ~= nil then
        commands[#commands + 1] = table.concat(pod_config.pod.commands, " ")
    end
    exec(table.concat(commands, " "), config.dryrun)
    -- create containers
    local containers = pod_config.containers
    for id = 1, #containers do
        local container = pod_config.container[containers[id]]
        if container__validate(container, pod_config.pod.name, containers[id]) then
            container__create(container, pod_config.pod, config)
        end
    end
end

---Remove pod and containers.
---@param pod_config table
---@param config table
local function pod__remove(pod_config, config)
    print("Remove pod '" .. pod_config.name .. "' ...")
    -- remove containers
    local containers = pod_config.containers
    for id = #containers, 1, -1 do -- reverse order when shutting down containers
        local container = pod_config.container[containers[id]]
        if container__validate(container, pod_config.pod.name, containers[id]) then
            container__remove(container, config)
        end
    end
    -- remove pod
    exec("podman pod rm " .. pod_config.pod.name, config.dryrun)
end

---Remove and create pod and containers.
---@param pod_config table
---@param config table
local function pod__recreate(pod_config, config)
    pod__remove(pod_config, config)
    pod__create(pod_config, config)
end

---Update containers of the pod.
---@param pod_config table
---@param config table
local function pod__update(pod_config, config)
    print("Update pod '" .. pod_config.name .. "' ...")
    local containers = pod_config.containers
    -- update containers
    for id = 1, #containers do
        local container = pod_config.container[containers[id]]
        if container__validate(container, pod_config.pod.name, containers[id]) then
            container__update(container, pod_config.pod, config)
        end
    end
end

-- ------------------------------------------------------------------------- --
--      Pod Config Handling
-- ------------------------------------------------------------------------- --

---Set path to default for pod configs if not defined in config.
---@param config table
---@return string
local function pod_config__ensure_path(config)
    local pod_config_path = "."
    if not string__is_nil_or_empty(config.configs.path) then
        pod_config_path = config.configs.path
    end
    return pod_config_path
end

---Load pod config.
---@param pod_config_path string
---@param pod_config_name string
---@return table|nil
local function pod_config__load(pod_config_path, pod_config_name)
    local pod_config_path = build_full_path(pod_config_path, pod_config_name, ".lua")
    local pod_config, error = load_lua_file(pod_config_path)
    if error then print_error(error) end
    if pod_config == nil then
        print_error("Couldn't load pod config '" .. pod_config_name .. "'! (" .. pod_config_path .. ")")
    end
    return pod_config
end

---Switch correct pod function and test pod values.
---@param pod_config table
---@param action string
---@param config table
local function pod_config__validate_and_handle(pod_config, target, action, config)
    -- test for pod config name
    if string__is_nil_or_empty(pod_config.name) then
        print_error("No pod config name in config '" .. target .. "' set!")
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
        pod__update(pod_config, config)
        return
    end
    if action == "recreate" then
        pod__recreate(pod_config, config)
        return
    end
    if action == "remove" then
        pod__remove(pod_config, config)
        return
    end
    if action == "create" then
        pod__create(pod_config, config)
        return
    end
end

---Loadn and handle single pod config.
---@param config table
---@param target string
---@param action string
local function pod_config__handle_single(config, target, action)
    -- assert pod config name
    local pod_config_name = ""
    if config.configs.cluster ~= nil then
        if table__contains(config.configs.cluster, target) then
            pod_config_name = target
        end
    end
    if config.configs.single ~= nil then
        if table__contains(config.configs.single, target) then
            pod_config_name = target
        end
    end
    if pod_config_name == "" then
        print_error("Pod config '" .. target .. "' not defined in config!")
        return
    end
    -- load pod config
    local pod_config_path = pod_config__ensure_path(config)
    local pod_config = pod_config__load(pod_config_path, pod_config_name)
    -- handle pod config
    if pod_config ~= nil then
        pod_config__validate_and_handle(pod_config, target, action, config)
    end
end

---Load and handle all pod configs in cluster.
---@param config table
---@param action string
local function pod_config__handle_all(config, action)
    local cluster = config.configs.cluster
    if cluster == nil or table__size(cluster) == 0 then
        print_error("No pod config names defined in config under cluster.")
        return
    end
    local pod_config_path = pod_config__ensure_path(config)
    for i = 1, #cluster do
        -- load pod config
        local pod_config = pod_config__load(pod_config_path, cluster[i])
        -- handle pod config
        if pod_config ~= nil then
            pod_config__validate_and_handle(pod_config, cluster[i], action, config)
        end
    end
end

-- ------------------------------------------------------------------------- --
--      Config Handling
-- ------------------------------------------------------------------------- --

---Load and test podscript config.
---@param config_name string
---@return table|nil
local function config__load_and_validate(config_name)
    local config, error = load_lua_file(config_name .. ".lua")
    if config == nil then
        if error then print_error(error) end
        print_error("Could not load '" .. config_name .. ".lua'!")
        return nil
    end
    -- dryrun default is true
    if config.dryrun == nil then
        config.dryrun = true
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
--      Main
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
    for i = 1, #arguments do
        if arguments[i] == "--help" then
            options.help = true
            break
        elseif arguments[i] == "--test" then
            options.test = true
        else
            if string__begins_with(arguments[i], "--") then
                print_error("Unknown option '" .. arguments[i] .. "'.")
                return true
            elseif options.action == "" then
                -- first argument is target
                options.action = arguments[i]
            elseif options.target == "" then
                -- second argument is action
                options.target = arguments[i]
            else
                print_error("Too many arguments.")
                return true
            end
        end
    end
    return false
end

---Main function.
local function main()
    -- default options
    local options = {}
    options.action = ""  -- action for target pod config
    options.help = false -- print help
    options.target = ""  -- target pod config name
    options.test = false -- use test config

    -- parse arguments
    if main__parse_arguments(arg, options) then return end

    -- print help
    if (options.help) then
        print_help()
        return
    end

    -- validate action
    if options.action == "" then
        print_error("No action set.")
        return
    end
    if not table__contains({ "create", "recreate", "remove", "update" }, options.action) then
        print_error("Unknown action '" .. options.action .. "'.")
        return
    end

    -- parse config
    local config_name = "config"
    if options.test then
        -- info test config
        print_info("Test config is used.")
        -- set test config name
        config_name = "config_test"
    end
    local config = config__load_and_validate(config_name)
    if config == nil then return end

    -- assert pod configs values
    if config.configs == nil then
        print_error("No pod config values defined in config!")
        return
    end

    -- info dryrun
    if config.dryrun then
        print_info("Dryrun mode is active.")
    end

    -- hande pod configs
    if options.target == "all" then
        pod_config__handle_all(config, options.action)
    else
        pod_config__handle_single(config, options.target, options.action)
    end
end

main()
