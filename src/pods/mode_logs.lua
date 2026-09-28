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
require "src.pods.utilities"
require "src.pods.recipe"
require "src.pods.system"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Logs
--
-- ------------------------------------------------------------------------- --

local function mode_logs__help(context)
    if context.flags.simulate then
        log.print("PodScript " .. get_version_string() .. " - Logs Mode (SIMULATED)\n")
        log.print("Simulate the execution of log commands for a recipe's pod or container.")
        log.print("Usage: pods simulate logs [OPTIONS] [<action>] <recipe>[/container]")
        log.print("   or: lua pods.lua simulate logs [OPTIONS] [<action>] <recipe>[/container]\n")
    else
        log.print("PodScript " .. get_version_string() .. " - Logs Mode\n")
        log.print("Show or follow logs for a recipe's pod or container.")
        log.print("Usage: pods logs [OPTIONS] [<action>] <recipe>[/container]")
        log.print("   or: lua pods.lua logs [OPTIONS] [<action>] <recipe>[/container]\n")
    end
    log.print("ACTIONS:")
    log.print("  show               fetch and display logs, then exit (default)")
    log.print("  follow             fetch and follow logs")
    log.print("  help               display this help\n")
    log.print("OPTIONS:")
    log.print("  --tail=<n>         output the specified number of lines at the end")
    log.print("  --since=<time>     show logs since timestamp")
    log.print("  --until=<time>     show logs until timestamp")
    log.print("  --timestamps       show timestamps in the log output")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output\n")
    log.print("TARGET:")
    log.print("  <recipe>             show logs for all containers in the recipe's pod")
    log.print("  <recipe>/<container> filter logs to a specific container (index, relative, absolute)")
end

local function mode_logs__execute(context, action, target)
    if string.is_nil_or_empty(target) then
        log.error("No recipe target specified.")
        return false
    end

    local recipe_name, container_spec = string.match(target, "^([^/]+)/(.*)$")
    if not recipe_name then
        recipe_name = target
        container_spec = nil
    end

    -- Load recipe
    local loaded_recipe = recipe__load(context.config.recipes.path, recipe_name)
    if not loaded_recipe then
        log.error("Recipe '" .. recipe_name .. "' could not be loaded.")
        return false
    end

    if not recipe__validate(context, loaded_recipe, recipe_name) then
        log.error("Recipe '" .. recipe_name .. "' is invalid.")
        return false
    end

    local commands = table.create(16)
    commands[#commands + 1] = "podman"
    commands[#commands + 1] = "pod"
    commands[#commands + 1] = "logs"
    commands[#commands + 1] = "-n"
    commands[#commands + 1] = "--color"

    if action == "follow" then
        commands[#commands + 1] = "-f"
    end

    if context.flags.since then
        commands[#commands + 1] = "--since"
        commands[#commands + 1] = string.escape_shell(tostring(context.flags.since))
    end
    if context.flags["until"] then
        commands[#commands + 1] = "--until"
        commands[#commands + 1] = string.escape_shell(tostring(context.flags["until"]))
    end
    if context.flags.tail then
        commands[#commands + 1] = "--tail"
        commands[#commands + 1] = tostring(context.flags.tail)
    end
    if context.flags.timestamps then
        commands[#commands + 1] = "--timestamps"
    end

    if container_spec and container_spec ~= "" then
        local container_name = recipe__resolve_container_name(loaded_recipe, container_spec)
        if not container_name then
            log.error("Container '" .. container_spec .. "' not found in recipe '" .. recipe_name .. "'.")
            return false
        end
        commands[#commands + 1] = "-c"
        commands[#commands + 1] = string.escape_shell(container_name)
    end

    commands[#commands + 1] = string.escape_shell(loaded_recipe.pod.name)
    
    local command_str = table.concat(commands, " ")

    if context.flags.simulate then
        log.print("Execute log command: ")
        log.print(command_str .. ";")
        return true
    else
        return os.execute(command_str)
    end
end

global function mode_logs__handle(context)
    local raw_target = context.targets[1]
    local action = context.action
    
    if action == "help" or (string.is_nil_or_empty(action) and string.is_nil_or_empty(raw_target)) then
        mode_logs__help(context)
        return
    end
    
    -- If action is not show, follow or help, it might be the target if the action was omitted
    if action ~= "show" and action ~= "follow" then
        if not string.is_nil_or_empty(raw_target) then
            log.error("Invalid action '" .. action .. "' or too many arguments.")
            return
        end
        raw_target = action
        action = "show"
    end
    
    if raw_target and string.begins_with(raw_target, "@") then
        log.error("Groups are not supported for logs. Only pods and containers are supported.")
        return
    end

    if #context.targets > 1 then
        log.error("Logs command only supports a single recipe target.")
        return
    end

    mode_logs__execute(context, action, raw_target)
end
