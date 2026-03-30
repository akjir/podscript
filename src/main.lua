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

            if string.begins_with(argument, "--") then
                if argument == "--config" then
                    skip = true
                    options.config = table.get_or_default(arguments, i + 1, "")
                elseif argument == "--debug" then
                    debug = true
                else
                    log.error("Unknown option '" .. argument .. "'.")
                    return true
                end
                -- check if argument is a mode
            elseif table.has_key(modes, argument) then
                if options.mode ~= nil then
                    log.error("Mode '" .. argument .. "' is already set.")
                    return true
                end
                options.mode = modes[argument]
            else
                if options.action == "" then
                    -- first argument is action
                    options.action = argument
                else
                    -- followed arguments are targets
                    table.insert(options.targets, argument)
                end
            end
        end
    end
    -- set default mode if not set
    if options.mode == nil then
        options.mode = modes["default"]
    end
    return false
end

---Main function.
---@param arguments string[]
---@build global:
function main(arguments)
    -- modes
    local modes = {
        default = default__handle,
        help = help__handle,
        simulate = simulate__handle,
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
    if main__parse_arguments(arguments, options, modes) then return end

    -- normalize config name
    local config_name = options.config
    if config_name ~= "config" and config_name ~= "" then
        config_name = normalize_name(config_name)
    end

    -- parse config
    local config_full_path = build_full_path(config_name, "", ".lua")
    local config = config__load_and_set_defaults(config_full_path)
    if config == nil then return end

    -- print info if non default confi is used and debug is enabled
    if config_name ~= "config" then
        log.debug("Config '" .. config_full_path .. "' is used.")
    end

    -- enforce simulate from arguments
    if options.simulate then
        config.simulate = true
    end

    -- if simulate is true, override default mode
    if options.mode == modes["default"] and config.simulate then
        options.mode = modes["simulate"]
    end

    -- handle mode
    options.mode(options, config)
end

-- prevent excecution when imported from test_suite
if arg[0] ~= "test.lua" then
    -- execute main
    main(arg)
end
