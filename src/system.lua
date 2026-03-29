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
--         SECTION System
--
--
-- ------------------------------------------------------------------------- --

system = {
    ---Check if the current Lua version is 5.4 or higher.
    ---@return boolean
    check_lua_version = function()
        local major, minor = _VERSION:match("Lua (%d+)%.(%d+)")
        major = tonumber(major)
        minor = tonumber(minor)

        if major > 5 or (major == 5 and minor >= 4) then
            return true
        end
        return false
    end,

    ---Check if the current operating system is Linux.
    ---@return boolean
    check_os = function()
        local handle = io.popen("uname -s")
        if handle == nil then return false end
        local result = handle:read("*a")
        handle:close()

        -- we need to trim the result, because uname -s returns a newline
        result = string.trim(result)

        return result == "Linux"
    end,

    ---Check if the current Podman version is 5.8.0 or higher.
    ---@return boolean
    check_podman_version = function()
        local handle = io.popen("podman version 2>&1")
        if handle == nil then return false end
        local result = handle:read("*a")
        handle:close()

        local version = result:match("Version:%s*(%d+%.%d+%.%d+)")
        if not version then return false end

        local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)")
        major = tonumber(major)
        minor = tonumber(minor)
        -- patch is not strictly needed for 5.8.0+, but good to have
        patch = tonumber(patch)

        if major > 5 or (major == 5 and minor >= 8) then
            return true
        end
        return false
    end,

    ---Execute a command.
    ---Only executes a command, if simulate is set to false.
    ---@param command string
    ---@param prefix string
    ---@param simulate boolean
    exec = function(command, prefix, simulate)
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
    end,

    ---Load a lua file.
    ---@param full_path string
    ---@return table|nil
    ---@return string|nil
    load_lua_file = function(full_path)
        local ok, result = pcall(dofile, full_path)
        if not ok then
            log.error(result)
            return nil, result
        end
        return result, nil
    end
}
