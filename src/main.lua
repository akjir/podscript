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
---@diagnostic disable: lowercase-global

require "src.header"
require "src.log"
require "src.helper_string"
require "src.helper_table"
require "src.helper"
require "src.config"
require "src.mode_default"
require "src.mode_simulate"
require "src.mode_help"
require "src.system"

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Main
--
-- ------------------------------------------------------------------------- --

---Parse arguments and retuns true if error.
---@param arguments string[]
---@param registry table
---@param startup_config table
---@param modes table
local function main__parse_arguments(arguments, registry, startup_config, modes)
    -- no arguments
    -- don't use table__size, it will be 2 (key -1 and 0 are used)
    if #arguments == 0 then
        startup_config.mode_selected = modes.help
        return false
    end
    -- parse arguments
    local mode_selected = false
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
        elseif table.has_key(modes, argument) then
            if not mode_selected then
                startup_config.mode_selected = modes[argument]
                mode_selected = true
            end
        else
            table.insert(registry.parameters, argument)
        end
    end
end

---Main function.
---@param arguments string[]
---@build global:
function main(arguments)
    local modes = {
        default = mode_default__handle,
        config = mode_config__handle,
        help = mode_help__handle,
        simulate = mode_simulate__handle,
    }

    local startup_config = {
        config_path = "config",
        mode_selected = modes.default,
    }

    local registry = {
        flags = {
            simulate = false,
        },
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
    main__parse_arguments(arguments, registry, startup_config, modes)

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
    if not config__load_and_set(config_full_path, registry, startup_config, modes) then
        return
    end

    -- handle mode
    startup_config.mode_selected(registry)
end

-- prevent excecution when imported from test_suite
if arg[0] ~= "test.lua" then
    -- execute main
    main(arg)
end
