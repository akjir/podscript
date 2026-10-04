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
--    SECTION Table
--
-- ------------------------------------------------------------------------- --

---Appends one or more sequential tables to another.
---Example: {1,2,3} and {4,5,6} will be {1,2,3,4,5,6}.
---@param target table|nil
---@param ... table|nil
function table.append(target, ...sources)
    if target == nil then return end
    for i = 1, sources.n do
        local source = sources[i]
        if source ~= nil then
            table.move(source, 1, #source, #target + 1, target)
        end
    end
end

---Test if a table contains a value. Only works with sequential tables.
---Returns false if table is nil or value is not found.
---@param target table|nil
---@param value any
---@return boolean
function table.contains(target, value)
    if target == nil then return false end
    for i = 1, #target do
        if (target[i] == value) then return true end
    end
    return false
end

---Get value from table or default if key not found.
---You can use "table and table[key] or default" instead, if there is no false value in table.
---@param target table
---@param key any
---@param default any
function table.get_or_default(target, key, default)
    if target == nil then return default end
    local value = target[key]
    if value ~= nil then
        return value
    end
    return default
end

---Check if a key exists in a table.
---@param target table
---@param key any
---@return boolean
function table.has_key(target, key)
    return target ~= nil and target[key] ~= nil
end

---Test if a table is nil or empty.
---@param target table
---@return boolean
function table.is_nil_or_empty(target)
    return target == nil or next(target) == nil
end

---Merges two or more tables by adding key-value pairs from sources to target.
---If a key from a source table already exists in the target table, its value will be overwritten.
---@param target table
---@param ... table
---@return table
function table.merge(target, ...sources)
    if target == nil then return sources[1] end
    for i = 1, sources.n do
        local source = sources[i]
        if source ~= nil then
            for key, value in pairs(source) do
                target[key] = value
            end
        end
    end
    return target
end

---Remove duplicates from a table. Returns a new table and don't modify the original.
---@param target table
---@return table
function table.remove_duplicates(target)
    if target == nil then return {} end
    local count = #target
    if count == 0 then return {} end

    local seen = table.create(0, count) -- Keeps track of values we've already encountered
    local result = table.create(count)  -- The new table with unique values
    local index = 1                     -- Manual index tracker is faster than table.insert

    for i = 1, count do
        local value = target[i]
        -- If the value hasn't been added to 'seen' yet...
        if not seen[value] then
            seen[value] = true    -- Mark it as seen
            result[index] = value -- Add it to the result array
            index = index + 1     -- Increment the index
        end
    end

    return result
end

---Get table size, including non-numeric keys.
---@param table table
---@return integer
function table.size(table)
    if table == nil then return 0 end
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
end

---Returns a sub-sequence of a sequential table, similar to string.sub.
---@param target table
---@param i integer|nil
---@param j integer|nil
---@return table
function table.sub(target, i, j)
    if type(target) ~= "table" then
        error("table.sub expects a table as target, got " .. type(target), 2)
    end
    local len = #target

    i = i or 1
    j = j or -1

    if i < 0 then i = len + i + 1 end
    if j < 0 then j = len + j + 1 end

    i = math.max(1, i)
    j = math.min(len, j)

    if i > j then return {} end

    local count = j - i + 1
    return table.move(target, i, j, 1, table.create(count))
end
