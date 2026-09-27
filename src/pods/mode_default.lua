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

require "src.pods.recipe"
require "src.pods.utilities"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Default
--
-- ------------------------------------------------------------------------- --

---Handle default mode.
---@param context table
global function mode_default__handle(context)
    log.debug("Default mode is used.")
    local action = context.action
    local targets = context.targets

    -- validate action
    if action == "" then
        log.error("No action set.")
        return
    end
    if not table.contains({ "create", "recreate", "remove", "update", "status" }, action) then
        log.error("Unknown action '" .. action .. "'.")
        return
    end

    -- validate targets
    if table.is_nil_or_empty(targets) and action ~= "status" then
        log.error("No targets set.")
        return
    end

    if action == "status" then
        if not table.is_nil_or_empty(targets) and targets[1] == "help" then
            pod__status_help(context)
        else
            pod__status(context)
        end
        return
    end

    -- targets are already untangled
    local untangled_targets = targets

    -- handle recipes
    local recipe_path = context.config.recipes.path
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
        if recipe ~= nil and recipe__validate(context, recipe, target) then
            --action is valid at this point
            pod_actions[action](recipe, context.config.simulate)
        end
    end
end
