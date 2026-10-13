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

---Collects all unique recipe names defined across all configuration groups.
---@param context table Application context containing configuration data.
---@return table recipe_list Sorted array of unique recipe names.
---@return table recipe_map Lookup table mapping each recipe name to true.
global function config__get_recipes(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    local config = context.config or {}
    local recipes = config.recipes or {}
    local groups = recipes.groups or {}
    local recipe_map = {}
    local recipe_list = {}

    for _, group_targets in pairs(groups) do
        if type(group_targets) == "table" then
            for _, target in ipairs(group_targets) do
                if type(target) == "string" and not string.begins_with(target, "@") then
                    local clean_target = string.trim(target)
                    if clean_target ~= "" and not recipe_map[clean_target] then
                        recipe_map[clean_target] = true
                        recipe_list[#recipe_list + 1] = clean_target
                    end
                end
            end
        end
    end

    table.sort(recipe_list)
    return recipe_list, recipe_map
end

---Checks if a specific recipe is defined within the application configuration.
---@param context table Application context containing configuration data.
---@param recipe_name string Name of the recipe to search for.
---@return boolean True if the recipe exists in a group, false otherwise.
global function config__has_recipe(context, recipe_name)
    if type(context) ~= "table" then error("context must be a table", 2) end
    local config = context.config or {}
    local recipes = config.recipes or {}
    local groups = recipes.groups or {}

    for _, group_targets in pairs(groups) do
        if type(group_targets) == "table" then
            if table.contains(group_targets, recipe_name) then
                return true
            end
        end
    end
    return false
end

---Resolves group aliases and expands targets into a unique list of individual recipe names.
---@param context table Application context containing configuration data.
---@param list table List of target strings (recipe names or @group aliases).
---@return table|boolean A deduplicated array of recipe names, or false if an error occurred.
global function config__untangle(context, list)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if log.debug_enabled and not table.is_nil_or_empty(list) then
        log.debug("Targets   - " .. table.concat(list, " "))
    end

    local targets = list
    local groups = {}
    if context.config and context.config.recipes and context.config.recipes.groups then
        groups = context.config.recipes.groups
    end

    local untangled = {}

    local function expand_group(group_target, visited)
        if string.find(group_target, "/") or string.find(group_target, ":") then
            log.error("Container targeting is not supported for groups: '" .. group_target .. "'.")
            return false
        end

        local group_name = string.sub(group_target, 2)
        local group_recipes = groups[group_name]

        if type(group_recipes) ~= "table" then
            log.error("Unknown recipe group '" .. group_target .. "'.")
            return false
        end

        if visited[group_name] then
            return true
        end
        visited[group_name] = true

        for j = 1, #group_recipes do
            local item = group_recipes[j]
            if string.begins_with(item, "@") then
                if not expand_group(item, visited) then
                    return false
                end
            else
                table.insert(untangled, item)
            end
        end

        visited[group_name] = false
        return true
    end

    for i = 1, #targets do
        local target = targets[i]

        -- 1. Handle group targeting (e.g., @group_name)
        if string.begins_with(target, "@") then
            if not expand_group(target, {}) then
                return false
            end

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
