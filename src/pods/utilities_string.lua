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

---Test if a string begins with another string.
---@param str string
---@param prefix string
---@return boolean
function string.begins_with(str, prefix)
    return str:sub(1, #prefix) == prefix
end

---Test if a string ends with another string.
---@param str string
---@param suffix string
---@return boolean
function string.ends_with(str, suffix)
    return str:sub(- #suffix) == suffix
end

---Escapes a string for safe use in shell commands.
---@param str string|nil
---@param always_quote boolean|nil
---@return string
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

---Test if string is empty or nil.
---@param str string|nil
---@return boolean
function string.is_nil_or_empty(str)
    return str == nil or str == ""
end

---Removes leading and trailing whitespaces.
---@param str string|nil
---@return string
function string.trim(str)
    if str == nil then return "" end
    -- avoid lazy evaluation of '.-' in str:match("^%s*(.-)%s*$")
    return str:match("^()%s*$") and "" or str:match("^%s*(.*%S)")
end

---Splits a string by a given separator.
---@param str string
---@param sep string
---@return table
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
