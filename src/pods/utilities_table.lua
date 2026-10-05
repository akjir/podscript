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

---Appends elements from one or more sequential tables into a target table.
---@param target table|nil The destination table.
---@param ... table|nil The source tables to append.
function table.append(target, ...sources)
    if target == nil then return end
    for i = 1, sources.n do
        local source = sources[i]
        if source ~= nil then
            table.move(source, 1, #source, #target + 1, target)
        end
    end
end

---Evaluates whether a sequential table contains a specific value.
---@param target table|nil The table to search.
---@param value any The value to locate.
---@return boolean True if the value is found, false otherwise.
function table.contains(target, value)
    if target == nil then return false end
    for i = 1, #target do
        if (target[i] == value) then return true end
    end
    return false
end

---Retrieves a value from a table by key, returning a fallback if missing.
---@param target table The table to query.
---@param key any The key to lookup.
---@param default any The fallback value.
---@return any The resolved value.
function table.get_or_default(target, key, default)
    if target == nil then return default end
    local value = target[key]
    if value ~= nil then
        return value
    end
    return default
end

---Evaluates whether a table contains a specific key.
---@param target table The table to inspect.
---@param key any The key to locate.
---@return boolean True if the key exists, false otherwise.
function table.has_key(target, key)
    return target ~= nil and target[key] ~= nil
end

---Evaluates whether a table is nil or contains no elements.
---@param target table The table to inspect.
---@return boolean True if nil or empty, false otherwise.
function table.is_nil_or_empty(target)
    return target == nil or next(target) == nil
end

---Merges key-value pairs from multiple source tables into a target table, overwriting existing keys.
---@param target table The destination table.
---@param ... table The source tables.
---@return table The merged target table.
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

---Creates a new sequential table containing only unique values from the source.
---@param target table The source table.
---@return table A new table free of duplicates.
function table.remove_duplicates(target)
    if type(target) ~= "table" then
        error("table.remove_duplicates expects a table as target, got " .. type(target), 2)
    end
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

---Counts the total number of key-value pairs in a table, including non-numeric keys.
---@param table table The table to measure.
---@return integer The total element count.
function table.size(table)
    if table == nil then return 0 end
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
end

---Extracts a sub-sequence from a sequential table, utilizing 1-based indexing.
---@param target table The source table.
---@param i integer|nil The starting index (inclusive, defaults to 1).
---@param j integer|nil The ending index (inclusive, defaults to -1).
---@return table A new table containing the extracted slice.
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
