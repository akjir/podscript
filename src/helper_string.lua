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

---@build block:
-- ------------------------------------------------------------------------- --
--
--
--         SECTION String
--
--
-- ------------------------------------------------------------------------- --

---Test if a string begins with another string.
---@param str string
---@param prefix string
---@return boolean
local function string__begins_with(str, prefix)
    return str:sub(1, #prefix) == prefix
end

---Test if a string ends with another string.
---@param str string
---@param suffix string
---@return boolean
local function string__ends_with(str, suffix)
    return str:sub(- #suffix) == suffix
end

---Test if string is empty or nil.
---@param str string|nil
---@return boolean
local function string__is_nil_or_empty(str)
    return str == nil or str == ""
end

---Removes leading and trailing whitespaces.
---@param str string
---@return string
local function string__trim(str)
    -- avoid lazy evaluation of '.-' in str:match("^%s*(.-)%s*$")
    return str:match("^()%s*$") and "" or str:match("^%s*(.*%S)")
end

-- add string helper functions to global string object
string.begins_with = string__begins_with
string.ends_with = string__ends_with
string.is_nil_or_empty = string__is_nil_or_empty
string.trim = string__trim
