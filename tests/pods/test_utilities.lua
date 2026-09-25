---@diagnostic disable: duplicate-set-field

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

---Recursively compares two tables for content equality.
---@param table1 table
---@param table2 table
---@return boolean
table.deep_compare = function(table1, table2)
    -- check for reference equality first for performance
    if table1 == table2 then return true end

    -- ensure both are tables
    if type(table1) ~= "table" or type(table2) ~= "table" then
        return false
    end

    -- compare table sizes
    if table.size(table1) ~= table.size(table2) then
        return false
    end

    -- iterate and compare key-value pairs
    for key, value1 in pairs(table1) do
        local value2 = table2[key]
        if type(value1) == "table" and type(value2) == "table" then
            if not table.deep_compare(value1, value2) then
                return false
            end
        elseif value1 ~= value2 then
            -- this handles primitives like strings, numbers, booleans, etc.
            return false
        end
    end
    return true
end

---Recursively converts a table into a readable string format.
---@param tbl table
---@return string
table.to_string = function(tbl)
    if tbl == nil then return "nil" end

    local parts = {}
    for key, value in pairs(tbl) do
        local key_string
        if type(key) == "string" then
            key_string = '"' .. key .. '"'
        else
            key_string = tostring(key)
        end

        local value_string
        if type(value) == "table" then
            value_string = table.to_string(value)
        elseif type(value) == "string" then
            value_string = '"' .. value .. '"'
        else
            value_string = tostring(value)
        end
        table.insert(parts, key_string .. "=" .. value_string)
    end

    return "{" .. table.concat(parts, ", ") .. "}"
end
