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
--
--         SECTION Helper
--
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

---Execute a command.
---Only executes a command, if simulate is set to false.
---@param command string
---@param prefix string
---@param simulate boolean
function exec(command, prefix, simulate)
    if not string.ends_with(command, ";") then
        command = command .. ";"
    end
    if simulate then
        if not string.is_nil_or_empty(prefix) then
            log.print(prefix)
        end
        log.print(command)
    else
        -- need better error handling, popen prints directly
        local handle = io.popen(command)
        if handle == nil then return end
        local output = handle:read("*l")
        if output ~= nil then
            log.print(prefix .. output)
        else
            log.print(prefix .. "...")
        end
        handle:close()
    end
end

---Normalizes a string by trimming outer whitespace, replacing internal spaces with underscores, and converting to lowercase.
---@param str string The input string to be normalized.
---@return string # The fully formatted string (e.g., " My  Name " becomes "my_name").
function normalize_name(str)
    -- if string.is_nil_or_empty(str) then return "" end -- shouldn't necessary
    return string.lower(str:trim():gsub("%s+", "_"))
end

---Load a lua file.
---@param full_path string
---@return table|nil
---@return string|nil
function load_lua_file(full_path)
    local ok, result = pcall(dofile, full_path)
    if not ok then
        log.error(result)
        return nil, result
    end
    return result, nil
end
