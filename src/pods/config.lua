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

require "src.pods.utilities"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Config
--
-- ------------------------------------------------------------------------- --

---Loads PodScript config. Sets default values if missing.
---Returns false if fails to load a file or no recipes are defined.
---@param context table
---@param test_path string|nil
---@return boolean
global function config__load_and_set(context, test_path)
    -- backward compatibility for tests
    local config_path = test_path
    if context.config and context.config.path then
        config_path = context.config.path
    end
    if not context.config then context.config = {} end
    if not context.config.path then context.config.path = config_path end
    if not context.config.pods then context.config.pods = { path = "" } end
    if not context.config.recipes then context.config.recipes = { path = ".", groups = {} } end

    local config, error, _ = system.load_lua_file(config_path)
    if config == nil then
        if error ~= nil then
            log.error(error)
        end
        log.error("Couldn't load configuration '" .. config_path .. "'!")
        return false
    end

    -- merge loaded config into context.config
    if config.simulate ~= nil then context.config.simulate = config.simulate end
    if config.editor ~= nil then context.config.editor = config.editor end

    if config.pods then
        if config.pods.path ~= nil then context.config.pods.path = config.pods.path end
        for k, v in pairs(config.pods) do
            if k ~= "path" then context.config.pods[k] = v end
        end
    end

    if config.recipes then
        if config.recipes.path ~= nil then context.config.recipes.path = config.recipes.path end
        if config.recipes.groups ~= nil then context.config.recipes.groups = config.recipes.groups end
        for k, v in pairs(config.recipes) do
            if k ~= "path" and k ~= "groups" then context.config.recipes[k] = v end
        end
    end

    -- set default path for recipes
    if string.is_nil_or_empty(context.config.recipes.path) then
        context.config.recipes.path = "."
    end

    -- check recipe values
    if table.is_nil_or_empty(config.recipes) then
        log.error("No recipes defined in config '" .. config_path .. "'!")
        return false
    else
        if table.is_nil_or_empty(config.recipes.groups) then
            log.error("No recipes groups defined in configuration '" .. config_path .. "'!")
            return false
        end
    end
    
    -- backwards compatibility for code tests that expect registry.recipes
    context.recipes = context.config.recipes
    
    return true
end

---Untangles recipe groups. Respects target order.
---First appearance of target stays, duplicates will be removed.
---Returns nil if a group or a recipe is not found.
---@param groups table
---@param targets table
---@return table|nil
global function config__untangle_recipes(groups, targets)
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
                log.error("Recipe '" .. target .. "' not found in config.")
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
