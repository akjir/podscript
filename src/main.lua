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
require "src.recipe"
require "src.mode_help"

---@build block:
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
        local argument = arguments[i]
        if skip == true then -- skips to allow "--argument value"
            skip = false
        else
            -- reset skip if used
            if skip then skip = false end

            if argument == "--help" then
                options.help = true
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
---@build global:
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
