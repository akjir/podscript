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
require "src.pods.utilities_system"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Connect
--
-- ------------------------------------------------------------------------- --

local function mode_connect__help(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if context.flags.simulate then
        log.print("PodScript " .. get_version_string() .. " - Connect Mode (SIMULATED)\n")
        log.print("Simulate connecting to a running container with an interactive shell.")
        log.print("Usage: pods simulate connect [OPTIONS] [<action>] <target>")
        log.print("   or: lua pods.lua simulate connect [OPTIONS] [<action>] <target>\n")
    else
        log.print("PodScript " .. get_version_string() .. " - Connect Mode\n")
        log.print("Connect to a running container with an interactive shell.")
        log.print("Usage: pods connect [OPTIONS] [<action>] <target>")
        log.print("   or: lua pods.lua connect [OPTIONS] [<action>] <target>\n")
    end
    log.print("ACTIONS:")
    log.print("  shell              open an interactive shell (default)")
    log.print("  help               display this help\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output\n")
    log.print("TARGET:")
    log.print("  <recipe>             connect to the container (if the recipe has exactly 1 container)")
    log.print("  <recipe>/<container> connect to a specific container (index, relative, absolute)")
    log.print("  <absolute_name>      connect directly to an absolute container name\n")
end

local function mode_connect__shell(context, target)
    if type(context) ~= "table" then error("context must be a table", 2) end

    local recipe_name, container_spec = string.match(target, "^([^/]+)/(.*)$")
    if not recipe_name then
        recipe_name = target
        container_spec = nil
    end

    local abs_container_name

    local recipe_file = util.build_full_path(context.config.recipes.path, recipe_name, ".lua")
    local recipe_exists = system.file_exists(recipe_file)

    local loaded_recipe
    if recipe_exists then
        loaded_recipe = recipe__load(context.config.recipes.path, recipe_name)
    end

    if recipe_exists then
        if not loaded_recipe then
            log.error("Recipe '" .. recipe_name .. "' could not be loaded.")
            return false
        end

        if not recipe__validate(context, loaded_recipe, recipe_name) then
            log.error("Recipe '" .. recipe_name .. "' is invalid.")
            return false
        end

        if not container_spec or container_spec == "" then
            if #loaded_recipe.containers == 1 then
                container_spec = "1"
            else
                log.error("Recipe '" .. recipe_name .. "' has multiple containers. Please specify one explicitly.")
                return false
            end
        end

        abs_container_name = recipe__resolve_container_name(loaded_recipe, container_spec)
        if not abs_container_name then
            log.error("Container '" .. container_spec .. "' not found in recipe '" .. recipe_name .. "'.")
            return false
        end
    else
        if not container_spec or container_spec == "" then
            -- Fallback to absolute container name if no recipe matches
            abs_container_name = recipe_name
        else
            log.error("Recipe '" .. recipe_name .. "' does not exist.")
            return false
        end
    end

    if not context.flags.simulate then
        if not system.container_exists(abs_container_name) then
            if not recipe_exists and (not container_spec or container_spec == "") then
                log.error("Target '" .. abs_container_name .. "' does not exist.")
            else
                log.error("Container '" .. abs_container_name .. "' is not running or does not exist.")
            end
            return false
        end
    end

    local escaped_name = string.escape_shell(abs_container_name)
    local command_str = "podman exec -it " .. escaped_name .. " sh -c 'command -v bash >/dev/null 2>&1 && exec bash || exec sh'"

    local success = system.exec(command_str, {
        simulate = context.flags.simulate,
        interactive = true,
        silent = true,
        prefix = "Execute connect command: "
    })
    return success
end

global function mode_connect__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    local action = context.parameters[1]
    local target = context.parameters[2]

    if action == "help" or string.is_nil_or_empty(action) then
        mode_connect__help(context)
        return
    end

    if action ~= "shell" then
        if not string.is_nil_or_empty(target) then
            log.error("Invalid action '" .. action .. "' or too many arguments.")
            return
        end
        target = action
        action = "shell"
    end

    if string.is_nil_or_empty(target) then
        log.error("No container target specified.")
        return
    end

    if string.begins_with(target, "@") then
        log.error("Groups are not supported for connect. Please specify a single target.")
        return
    end

    if #context.parameters > 2 then
        log.error("Connect command only supports a single target.")
        return
    end

    mode_connect__shell(context, target)
end
