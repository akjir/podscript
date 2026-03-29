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
--
--         SECTION Config
--
--
-- ------------------------------------------------------------------------- --

---Loads PodScript config. Sets default values if missing.
---Returns nil if fails to load a file or no recipes are defined.
---@param config_full_path string
---@return table|nil
function config__load_and_set_defaults(config_full_path)
    local config, _ = load_lua_file(config_full_path)
    if config == nil then
        log.error("Couldn't load configuration '" .. config_full_path .. "'!")
        return nil
    end

    if config.recipes == nil then
        log.error("No recipes defined in config '" .. config_full_path .. "'!")
        return nil
    else
        if table.is_nil_or_empty(config.recipes.groups) then
            log.error("No recipes groups defined in configuration '" .. config_full_path .. "'!")
            return nil
        end

        -- set default path for recipes or correct them
        if string.is_nil_or_empty(config.recipes.path) then
            config.recipes.path = "./"
        end
    end

    -- simulate default is true
    if config.simulate == nil then
        config.simulate = true
    end

    -- default pod values
    if config.pods == nil then
        config.pods = {}
    end

    -- default pod path
    if config.pods.path == nil then
        config.pods.path = "" -- no path set, pods need to define a path
    end

    return config
end

---Untangles recipe groups. Respects target order.
---First appearance of target stays, duplicates will be removed.
---Returns nil if a group or a recipe is not found.
---@param groups table
---@param targets table
---@return table|nil
function config__untangle_recipes(groups, targets)
    if debug then
        log.debug("Targets   - " .. table.concat(targets, " "))
    end

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
    if debug then
        log.debug("Untangled - " .. table.concat(untangled, " "))
    end
    return untangled
end
