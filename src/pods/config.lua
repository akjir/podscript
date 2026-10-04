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

require "src.pods.log"
require "src.pods.utilities"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Config
--
-- ------------------------------------------------------------------------- --

---Check if a recipe is defined in the configuration.
---@param context table
---@param recipe_name string
---@return boolean
global function config__has_recipe(context, recipe_name)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.recipes = context.config.recipes or {}
    local groups = context.config.recipes.groups or {}

    for _, group_targets in pairs(groups) do
        if type(group_targets) == "table" then
            if table.contains(group_targets, recipe_name) then
                return true
            end
        end
    end
    return false
end

---Untangle targets from configuration groups.
---@param context table
---@param list table
---@return table|boolean
global function config__untangle(context, list)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    if log.debug_enabled and not table.is_nil_or_empty(list) then
        log.debug("Targets   - " .. table.concat(list, " "))
    end

    local targets = list
    local groups = {}
    if context.config and context.config.recipes and context.config.recipes.groups then
        groups = context.config.recipes.groups
    end

    local untangled = {}

    for i = 1, #targets do
        local target = targets[i]

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
        elseif (target == "help" or target == "") then
            table.insert(untangled, target)

        -- 3. Handle individual recipe targeting
        else
            if not config__has_recipe(context, target) then
                log.error("Recipe '" .. target .. "' not found in config.")
                return false
            end

            table.insert(untangled, target)
        end
    end

    local final_untangled = table.remove_duplicates(untangled)

    if log.debug_enabled and not table.is_nil_or_empty(final_untangled) then
        log.debug("Untangled - " .. table.concat(final_untangled, " "))
    end

    return final_untangled
end
