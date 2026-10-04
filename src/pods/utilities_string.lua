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

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION String
--
-- ------------------------------------------------------------------------- --

---Evaluates whether a string starts with a specified prefix.
---@param str string The source string to evaluate.
---@param prefix string The prefix to search for.
---@return boolean True if the string starts with the prefix, false otherwise.
function string.begins_with(str, prefix)
    return str:sub(1, #prefix) == prefix
end

---Evaluates whether a string ends with a specified suffix.
---@param str string The source string to evaluate.
---@param suffix string The suffix to search for.
---@return boolean True if the string ends with the suffix, false otherwise.
function string.ends_with(str, suffix)
    return str:sub(- #suffix) == suffix
end

---Escapes a string securely for injection into shell commands.
---@param str string|nil The string to escape.
---@param always_quote boolean|nil True to wrap the string in single quotes unconditionally.
---@return string The safely escaped shell string.
function string.escape_shell(str, always_quote)
    if str == nil then
        return "''"
    end
    str = tostring(str)
    if always_quote or str == "" or str:find("[^%w_%-./:=@]") then
        return "'" .. str:gsub("'", "'\\''") .. "'"
    end
    return str
end

---Evaluates whether a string is nil or strictly empty.
---@param str string|nil The string to evaluate.
---@return boolean True if the string is nil or empty, false otherwise.
function string.is_nil_or_empty(str)
    return str == nil or str == ""
end

---Strips leading and trailing whitespace characters from a string.
---@param str string|nil The string to trim.
---@return string The trimmed string, or an empty string if nil.
function string.trim(str)
    if str == nil then return "" end
    -- avoid lazy evaluation of '.-' in str:match("^%s*(.-)%s*$")
    return str:match("^()%s*$") and "" or str:match("^%s*(.*%S)")
end

---Partitions a string into a table of substrings divided by a given separator.
---@param str string The string to partition.
---@param sep string The separator substring.
---@return table An array of resulting substrings.
function string.split(str, sep)
    if sep == nil or sep == "" then
        return {str}
    end
    local result = {}
    local last_end = 1
    local s, e = str:find(sep, 1, true)
    while s do
        result[#result + 1] = str:sub(last_end, s - 1)
        last_end = e + 1
        s, e = str:find(sep, last_end, true)
    end
    result[#result + 1] = str:sub(last_end)
    return result
end

---Computes the visible character count of a string, accounting for multi-byte UTF-8 sequences.
---@param str string The string to measure.
---@return integer The visible character length.
function string.visible_length(str)
    if str == nil then return 0 end
    local extra = 0
    for i = 1, #str do
        local b = str:byte(i)
        if b >= 0x80 and b <= 0xBF then
            extra = extra + 1
        end
    end
    return #str - extra
end
