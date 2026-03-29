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

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Table
--
-- ------------------------------------------------------------------------- --

---Appends a sequential table to another.
---Example: {1,2,3} and {4,5,6} will be {1,2,3,4,5,6}.
---@param target table|nil
---@param source table|nil
table.append = function(target, source)
    if target == nil then return end
    if source == nil then return end
    table.move(source, 1, #source, #target + 1, target)
end

---Test if a table contains a value. Only works with sequential tables.
---Returns false if table is nil or value is not found.
---@param table table|nil
---@param value any
---@return boolean
table.contains = function(table, value)
    if table == nil then return false end
    for i = 1, #table do
        if (table[i] == value) then return true end
    end
    return false
end

---Remove duplicates from a table. Returns a new table and don't modify the original.
---@param table table
---@return table
table.remove_duplicates = function(table)
    local seen = {}   -- Keeps track of values we've already encountered
    local result = {} -- The new table with unique values
    local index = 1   -- Manual index tracker is faster than table.insert

    for i = 1, #table do
        local value = table[i]
        -- If the value hasn't been added to 'seen' yet...
        if not seen[value] then
            seen[value] = true    -- Mark it as seen
            result[index] = value -- Add it to the result array
            index = index + 1     -- Increment the index
        end
    end

    return result
end

---Get value from table or default if key not found
---@param table table|nil
---@param key any
---@param default any
table.get_or_default = function(table, key, default)
    if table == nil then return default end
    local value = table[key]
    if value == nil then
        return default
    else
        return value
    end
end

---Test if a table is nil or empty.
---@param table table|nil
---@return boolean
table.is_nil_or_empty = function(table)
    return table == nil or next(table) == nil
end

---Merges two tables by adding key-value pairs from one table to another.
---If a key from the source table already exists in the target table, its value will be overwritten.
---@param target table|nil
---@param source table|nil
table.merge = function(target, source)
    if target == nil then return source end
    if source == nil then return target end
    for key, value in pairs(source) do
        target[key] = value
    end
end

---Get table size, including non-numeric keys.
---@param table table
---@return integer
table.size = function(table)
    if table == nil then return 0 end
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
end
