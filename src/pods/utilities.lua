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
---@diagnostic disable: duplicate-set-field
---@diagnostic disable: lowercase-global

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Utilities
--
-- ------------------------------------------------------------------------- --

global util <const> = {}

---Constructs a complete file path from a base directory, filename, and extension.
---@param path string The base directory path.
---@param file_name string The name of the file.
---@param file_extension string The extension to append (e.g., '.lua').
---@return string The fully resolved file path.
function util.build_full_path(path, file_name, file_extension)
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

---Formats a line by padding it with spaces until the target column is reached, then appending the status.
---@param line string The line content.
---@param status string The status to append.
---@param target_column integer|nil The target column for alignment (default: 44).
---@return string # The fully formatted line.
function util.format_line(line, status, target_column)
    local visible = string.visible_length(line)
    local pad = (target_column or 44) - visible
    if pad < 1 then pad = 1 end
    return line .. string.rep(" ", pad) .. status
end

---Normalizes a name by converting it to lowercase, trimming whitespace, and replacing internal spaces with underscores.
---@param str string The name to normalize.
---@return string # The normalized name.
function util.normalize_name(str)
    return string.lower(str:trim():gsub("%s+", "_"))
end

---Splits a string by the first equals sign. If no equals sign is found, the value is set to true (as flag is given).
---@param argument string The input string to be split.
---@return string, string|boolean # The key and value.
function util.split_argument(argument)
    local clean_argument = string.gsub(argument, "^%-+", "")
    local parameter, value = string.match(clean_argument, "^([^=]+)=(.*)$")
    if parameter then
        return parameter, value
    end
    return clean_argument, true
end
