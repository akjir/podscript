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

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Helper
--
-- ------------------------------------------------------------------------- --

---Build a full path with given parts.
---@param path string
---@param file_name string
---@param file_extension string
---@return string
function build_full_path(path, file_name, file_extension)
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
function normalize_name(str)
    return string.lower(str:trim():gsub("%s+", "_"))
end

---Parse the action and targets parameters from a registry.
---@param registry table The registry to parse.
---@return string, table # The action and targets.
function parse_action_and_targets_parameters(registry)
    local parameters = registry.parameters
    local targets = table.move(parameters, 2, #parameters, 1, {})
    return parameters[1] or "", targets
end

---Splits a string by the first equals sign. If no equals sign is found, the value is set to true (as flag is given).
---@param argument string The input string to be split.
---@return string, string|boolean # The key and value.
function split_argument(argument)
    local clean_argument = string.gsub(argument, "^%-+", "")
    local parameter, value = string.match(clean_argument, "^([^=]+)=(.*)$")
    if parameter then
        return parameter, value
    end
    return clean_argument, true
end
