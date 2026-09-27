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
require "src.pods.config"
require "src.pods.mode_command"
require "src.pods.mode_recipe"
require "src.pods.mode_config"
require "src.pods.mode_default"
require "src.pods.mode_simulate"
require "src.pods.mode_help"
require "src.pods.mode_init"
require "src.pods.system"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Main
--
-- ------------------------------------------------------------------------- --

---Parse arguments and retuns true if error.
---@param context table
---@param arguments string[]
---@param modes table
local function main__parse_arguments(context, arguments, modes)
    -- no arguments
    -- don't use table__size, it will be 2 (key -1 and 0 are used)
    if #arguments == 0 then
        context.mode.selected = modes.help
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
                local parameter, value = split_argument(argument)
                context.flags[parameter] = value
            end
            -- check if argument is a mode
        else
            local is_mode = (not has_seen_positional) and modes[argument]
            has_seen_positional = true
            if is_mode then
                context.mode.selected = modes[argument]
            else
                table.insert(context.parameters, argument)
            end
        end
    end
end

---Parse the action and targets parameters from the context.
---@param context table
local function main__parse_action_and_targets(context)
    local parameters = context.parameters
    context.action = parameters[1] or ""
    context.targets = table.move(parameters, 2, #parameters, 1, {})
end

---Main function.
---@param arguments string[]
---@build global:
global function main(arguments)
    local modes = {
        command = mode_command__handle,
        config = mode_config__handle,
        default = mode_default__handle,
        help = mode_help__handle,
        init = mode_init__handle,
        recipe = mode_recipe__handle,
        simulate = mode_simulate__handle,
    }

    local context = {
        -- MUTABLE: Populated and mutated by config.lua loaders
        config = {
            name = "config", -- The provided config name
            path = "",       -- The resolved full path to the config file
            simulate = true, -- Default simulate value
            editor = "",     -- Default editor
            pods = { path = "" },
            recipes = { path = ".", groups = {} },
        },

        -- READ-ONLY (RO): Parsed once from CLI
        flags = {},          -- Parsed command-line flags (e.g., { ["--debug"] = true })
        parameters = {},     -- Parsed positional command-line arguments

        -- READ-ONLY (RO) after main.lua initialization
        mode = {
            selected = modes.default, -- The selected mode handler function
        },

        -- READ-ONLY (RO): Parsed centrally in main.lua after config load
        action = "",         -- The single action to execute
        targets = {},        -- The untangled list of targets
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
        config_name = normalize_name(config_name)
    end

    -- build full config path
    local config_full_path = context.config.path
    if config_full_path == "" then
        config_full_path = build_full_path(config_name, "", ".lua")
    else
        config_full_path = build_full_path(context.config.path, "", ".lua")
    end

    -- print debug message if non-default-configuration is used
    if log.debug_enabled and config_name ~= "config" then
        log.print("DEBUG: Config '" .. config_full_path .. "' is used.")
    end

    context.config.path = config_full_path

    -- handle modes that do not require configuration
    if context.mode.selected == modes.init or context.mode.selected == modes.help then
        context.mode.selected(context)
        return
    end

    -- parse config
    if not config__load_and_set(context) then
        return
    end

    main__parse_action_and_targets(context)

    -- config simulate activates simulate mode if default mode is selected
    if context.config.simulate and context.mode.selected == modes["default"] then
        context.mode.selected = modes["simulate"]
    end

    -- handle mode
    context.mode.selected(context)
end

-- prevent excecution when imported from test_suite
if arg[0] ~= "test.lua" then
    -- execute main
    main(arg)
end
