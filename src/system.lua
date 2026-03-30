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
--    SECTION System
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
        local handle = io.popen("podman --version 2>&1")
        if handle == nil then return false end
        local result = handle:read("*a")
        handle:close()

        -- podman --version returns something like "podman version 5.8.1"
        local major_string, minor_string = result:match("version%s*(%d+)%.(%d+)%.%d+")
        if not major_string or not minor_string then return false end

        local major = tonumber(major_string)
        local minor = tonumber(minor_string)

        return major > 5 or (major == 5 and minor >= 8)
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
            -- combine STDOUT and STDERR using 2>&1
            local handle = io.popen(command .. " 2>&1")
            if handle == nil then
                log.error("Failed to execute command '" .. command .. "'!")
                return
            end

            local output = handle:read("*a")
            local success, exit_type, exit_code = handle:close()
            if output ~= nil and output ~= "" then
                -- include the error message if the command failed
                log.print(prefix .. output:gsub("%s+$", ""))
            else
                log.print(prefix .. "...")
            end

            -- check if the command actually succeeded
            if not success then
                log.error("Command exited with code '" .. tostring(exit_code) .. "'!")
            end
        end
    end,

    --- Loads a Lua file and returns the result.
    --- @param full_path string
    --- @return table|nil result The object returned by the file (usually a table).
    --- @return string|nil error Error message if something went wrong.
    --- @return string|nil error_type The type of error ("load" or "execution").
    load_lua_file = function(full_path)
        local chunk, err = loadfile(full_path)
        if chunk == nil then
            return nil, err, "load"
        end
        local success, result = pcall(chunk)
        if not success then
            return nil, result, "execution"
        end
        return result, nil, nil
    end,
}
