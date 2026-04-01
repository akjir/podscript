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

require "src.helper"

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Config
--
-- ------------------------------------------------------------------------- --

---Loads PodScript config. Sets default values if missing.
---Returns false if fails to load a file or no recipes are defined.
---@param registry table
---@param config_full_path string
---@return boolean
function config__load_and_set(registry, config_full_path)
    local config, error, _ = system.load_lua_file(config_full_path)
    if config == nil then
        if error ~= nil then
            log.error(error)
        end
        log.error("Couldn't load configuration '" .. config_full_path .. "'!")
        return false
    end

    -- config values
    registry.config = config
    if registry.config.simulate == nil then
        registry.config.simulate = true
    end

    -- pod values
    if not registry.config.pods then
        registry.config.pods = {}
    end
    if not registry.config.pods.path then
        registry.config.pods.path = "" -- no path set, pods need to define a path
    end

    -- recipes values
    registry.recipes = config.recipes
    if table.is_nil_or_empty(registry.recipes) then
        log.error("No recipes defined in config '" .. config_full_path .. "'!")
        return false
    else
        if table.is_nil_or_empty(registry.recipes.groups) then
            log.error("No recipes groups defined in configuration '" .. config_full_path .. "'!")
            return false
        end
        -- set default path for recipes or correct them
        if string.is_nil_or_empty(registry.recipes.path) then
            registry.recipes.path = "."
        end
    end
    return true
end

---Untangles recipe groups. Respects target order.
---First appearance of target stays, duplicates will be removed.
---Returns nil if a group or a recipe is not found.
---@param groups table
---@param targets table
---@return table|nil
function config__untangle_recipes(groups, targets)
    log.debug("Targets   - " .. table.concat(targets, " "))
    local untangled = {}

    for i = 1, #targets do
        local target = targets[i]

        -- handle group
        if string.begins_with(target, "@") then
            local group_recipes = groups[target:sub(2)] -- remove @ from target

            if group_recipes == nil then
                log.error("Unknown recipe group '" .. target .. "'.")
                return nil
            end

            table.append(untangled, group_recipes)
        else -- handle single target
            local found = nil

            for _, group_targets in pairs(groups) do
                if table.contains(group_targets, target) then
                    found = target
                    break
                end
            end

            if found == nil then
                log.error("Target '" .. target .. "' not found in config.")
                return nil
            else
                table.insert(untangled, found)
            end
        end
    end

    untangled = table.remove_duplicates(untangled)
    log.debug("Untangled - " .. table.concat(untangled, " "))
    return untangled
end
