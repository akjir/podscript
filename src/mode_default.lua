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
---@param options table
---@param config table
function default__handle(options, config)
    -- validate action
    if string.is_nil_or_empty(options.action) then
        log.error("No action set.")
        return
    end
    if not table.contains({ "create", "recreate", "remove", "update" }, options.action) then
        log.error("Unknown action '" .. options.action .. "'.")
        return
    end

    -- validate targets
    if table.is_nil_or_empty(options.targets) then
        log.error("No targets set.")
        return
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
