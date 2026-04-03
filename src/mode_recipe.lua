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
    log.print("Usage: pods recipe [OPTIONS] NAME ACTION")
    log.print("   or: lua pods.lua recipe [OPTIONS] NAME ACTION\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path\n")
    log.print("NAME:")
    log.print("  *                  name of the recipe\n")
    log.print("ACTIONS:")
    log.print("  help               display this help and exit")
    log.print("  print              print recipe")
end

---Print config.
---@param registry table
---@param name string
local function mode_recipe__print(registry, name)
    local recipe_path = registry.recipes.path
    local recipe = recipe__load(recipe_path, name)
    if recipe == nil then return end

    local yaml_lines = table.to_yaml_lines(recipe)
    for i = 1, #yaml_lines do
        local prefix = string.format("%3d: ", i)
        log.print(prefix .. yaml_lines[i])
    end
end

---Handle config mode.
---@param registry table
function mode_recipe__handle(registry)
    local name, targets = parse_action_and_targets_parameters(registry)
    local action = targets[1]
    local actions = {
        help = mode_recipe__help,
        print = mode_recipe__print
    }
    local execute = actions[action] or function()
        log.error("Unknown action: " .. tostring(action))
    end
end
