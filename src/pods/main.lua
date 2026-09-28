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
require "src.pods.mode_recipe"
require "src.pods.mode_config"
require "src.pods.mode_default"
require "src.pods.mode_simulate"
require "src.pods.mode_help"
require "src.pods.mode_init"
require "src.pods.mode_logs"
require "src.pods.system"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Main
--
-- ------------------------------------------------------------------------- --

---Loads PodScript config. Sets default values if missing.
---Returns false if fails to load a file or no recipes are defined.
---@param context table
---@return boolean
global function main__config_load_and_set(context)
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
---@param context table The runtime context containing parameters and configuration.
---@param modes table The available execution modes.
---@return boolean success True if parsing was successful, false otherwise.
local function main__parse_action_and_targets(context, modes)
    local parameters = context.parameters
    local param_offset = 0

    local is_simulate = context.mode.selected == modes.simulate
    if is_simulate and (parameters[1] == "command" or parameters[1] == "logs") then
        param_offset = 1
    end

    local is_command = context.mode.selected == modes.command or (is_simulate and parameters[1] == "command")
    local is_logs = context.mode.selected == modes.logs or (is_simulate and parameters[1] == "logs")

    local raw_targets = {}

    if is_command then
        -- Syntax for command mode: podscript command <recipe> <command_to_execute>
        local recipe_target = parameters[1 + param_offset]
        if recipe_target then
            table.insert(raw_targets, recipe_target)
        end
        context.targets = { parameters[2 + param_offset] }
    else
        -- Syntax for default mode: podscript <action> <target1> <target2> ...
        context.action = parameters[1 + param_offset] or ""
        raw_targets = table.move(parameters, 2 + param_offset, #parameters, 1, {})
    end

    if log.debug_enabled and not table.is_nil_or_empty(raw_targets) then
        log.debug("Targets   - " .. table.concat(raw_targets, " "))
    end

    local groups = {}
    if context.config and context.config.recipes and context.config.recipes.groups then
        groups = context.config.recipes.groups
    end

    local untangled = {}

    for i = 1, #raw_targets do
        local target = raw_targets[i]

        -- 1. Handle group targeting (e.g., @group_name)
        if string.begins_with(target, "@") then
            if string.find(target, "/") or string.find(target, ":") then
                log.error("Container targeting is not supported for groups: '" .. target .. "'.")
                return false
            end

            local group_name = string.sub(target, 2)
            local group_recipes = groups[group_name]

            if group_recipes == nil then
                log.error("Unknown recipe group '" .. target .. "'.")
                return false
            end

            table.append(untangled, group_recipes)

        -- 2. Handle specific edge cases (help or empty string)
        elseif (is_command or context.action == "status") and (target == "help" or target == "") then
            table.insert(untangled, target)

        -- 3. Handle individual recipe targeting
        else
            local target_recipe = target

            -- Logs mode allows optional container paths (e.g., recipe/container)
            if is_logs then
                local slash_pos = string.find(target, "/")
                if slash_pos then
                    target_recipe = string.sub(target, 1, slash_pos - 1)
                end
            end

            -- Verify that the target recipe exists in the configuration groups
            local is_valid_recipe = false
            for _, group_targets in pairs(groups) do
                if table.contains(group_targets, target_recipe) then
                    is_valid_recipe = true
                    break
                end
            end

            if not is_valid_recipe then
                log.error("Recipe '" .. target_recipe .. "' not found in config.")
                return false
            end

            table.insert(untangled, target)
        end
    end

    local final_untangled = table.remove_duplicates(untangled)

    if log.debug_enabled and not table.is_nil_or_empty(final_untangled) then
        log.debug("Untangled - " .. table.concat(final_untangled, " "))
    end

    -- Assign final processed values to context variables
    if is_command then
        context.action = final_untangled[1] or ""
    else
        context.targets = final_untangled
    end

    return true
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
        logs = mode_logs__handle,
        recipe = mode_recipe__handle,
        simulate = mode_simulate__handle,
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
    if not main__config_load_and_set(context) then
        return
    end

    if not main__parse_action_and_targets(context, modes) then
        return
    end

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
