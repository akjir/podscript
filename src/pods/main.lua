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

require "src.pods.header"
require "src.pods.log"
require "src.pods.utilities_string"
require "src.pods.utilities_table"
require "src.pods.utilities"
require "src.pods.mode_command"
require "src.pods.mode_connect"
require "src.pods.mode_recipe"
require "src.pods.mode_config"
require "src.pods.mode_default"
require "src.pods.mode_help"
require "src.pods.mode_init"
require "src.pods.mode_logs"
require "src.pods.utilities_system"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Main
--
-- ------------------------------------------------------------------------- --

---Loads the PodScript configuration file and populates the application context. Sets default values for missing fields.
---@param context table The application context object to modify.
---@return boolean True if the configuration was successfully loaded and contains recipes, false otherwise.
global function main__config_load_and_set(context)
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
---@build global:
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
