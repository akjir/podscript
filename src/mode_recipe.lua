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
require "src.helper"

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Config
--
-- ------------------------------------------------------------------------- --

---Print config help.
function mode_recipe__help()
    log.print("PODSCRIPT " .. VERSION .. "\n")
    log.print("Usage: pods recipe [OPTIONS] ACTION NAME")
    log.print("   or: lua pods.lua recipe [OPTIONS] ACTION NAME\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path\n")
    log.print("ACTIONS:")
    log.print("  help               display this help and exit")
    log.print("  print              print recipe\n")
    log.print("NAME:")
    log.print("  *                  name of the recipe")
end

---Print recipe content.
---@param registry table
---@param name string
local function mode_recipe__print(registry, name)
    if string.is_nil_or_empty(name) then
        log.error("No recipe name given.")
        return
    end
    local normalized_name = normalize_name(name)
    local found = config__untangle_recipes(registry.config.recipes.groups, { normalized_name })
    -- config__untangle_recipes already logs the error
    if found == nil then return end

    local recipe_path = registry.recipes.path
    local full_path = build_full_path(recipe_path, normalized_name, ".lua")

    local lines = system.read_file_content_by_line(full_path)
    if not lines then return end

    for i = 1, #lines do
        local prefix = string.format("%3d: ", i)
        log.print(prefix .. lines[i])
    end
end

---Handle recipe mode.
---@param registry table
function mode_recipe__handle(registry)
    log.debug("Recipe mode is used.")
    local action = registry.parameters[1]
    if action == nil then
        log.error("No action given.")
        return
    end
    local name = registry.parameters[2]
    if string.is_nil_or_empty(action) or action == "help" then
        action = "help"
    end
    local actions = {
        help = mode_recipe__help,
        print = mode_recipe__print
    }
    local execute = actions[action] or function(_, _)
        log.error("Unknown action: " .. tostring(action))
    end
    execute(registry, name)
end
