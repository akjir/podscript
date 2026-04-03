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

require "src.config"
require "src.recipe"
require "src.helper"

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Default
--
-- ------------------------------------------------------------------------- --

---Handle default mode.
---@param registry table
function mode_default__handle(registry)
    local action, targets = parse_action_and_targets_parameters(registry)

    -- validate action
    if action == "" then
        log.error("No action set.")
        return
    end
    if not table.contains({ "create", "recreate", "remove", "update" }, action) then
        log.error("Unknown action '" .. action .. "'.")
        return
    end

    -- validate targets
    if table.is_nil_or_empty(targets) then
        log.error("No targets set.")
        return
    end

    -- clean up targets
    local untangled_targets = config__untangle_recipes(registry.recipes.groups, targets)
    if untangled_targets == nil then return end

    -- handle recipes
    local recipe_path = registry.recipes.path
    local pod_actions = {
        create   = pod__create,
        recreate = pod__recreate,
        remove   = pod__remove,
        update   = pod__update,
    }
    for i = 1, #untangled_targets do
        local target = untangled_targets[i]
        -- load recipe
        local recipe = recipe__load(recipe_path, target)
        -- handle recipe
        if recipe ~= nil and recipe__validate(registry, recipe, target) then
            --- action is valid at this point
            pod_actions[action](recipe, registry.flags.simulate)
        end
    end
end
