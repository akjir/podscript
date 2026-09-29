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
global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Utilities
--
-- ------------------------------------------------------------------------- --

---Build a full path with given parts.
---@param path string
---@param file_name string
---@param file_extension string
---@return string
global function build_full_path(path, file_name, file_extension)
    if not string.begins_with(path, "/") and
        not string.begins_with(path, ".")
    then
        path = "./" .. path
    end
    if string.is_nil_or_empty(file_name) then
        if string.is_nil_or_empty(file_extension) then
            return path
        else
            return path .. file_extension
        end
    elseif string.ends_with(path, "/") or string.begins_with(file_name, "/") then
        return path .. file_name .. file_extension
    else
        return path .. "/" .. file_name .. file_extension
    end
end

---Normalizes a string by trimming outer whitespace, replacing internal spaces with underscores, and converting to lowercase.
---@param str string The input string to be normalized.
---@return string # The fully formatted string (e.g., " My  Name " becomes "my_name").
global function normalize_name(str)
    return string.lower(str:trim():gsub("%s+", "_"))
end


---Splits a string by the first equals sign. If no equals sign is found, the value is set to true (as flag is given).
---@param argument string The input string to be split.
---@return string, string|boolean # The key and value.
global function split_argument(argument)
    local clean_argument = string.gsub(argument, "^%-+", "")
    local parameter, value = string.match(clean_argument, "^([^=]+)=(.*)$")
    if parameter then
        return parameter, value
    end
    return clean_argument, true
end

local function untangle_groups(context, list)
    if log.debug_enabled and not table.is_nil_or_empty(list) then
        log.debug("Targets   - " .. table.concat(list, " "))
    end

    local targets = {}
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
            local target_recipe = target

            -- Verify that the target recipe exists in the configuration groups
            local is_valid_recipe = false
            for _, group_targets in pairs(groups) do
                if table.contains(group_targets, target_recipe) then
                    is_valid_recipe = true
                    break
                end
            end

            if not is_valid_recipe then
                log.error("Recipe '" .. target_recipe .. "' not found in config.")
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
