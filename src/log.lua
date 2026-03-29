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
--         SECTION Log
--
--
-- ------------------------------------------------------------------------- --

log = {
    -- Proxy to handle output, defaults to standard print
    print = print,

    ---Print debug.
    ---@param message string
    debug = function(message)
        log.print("DEBUG: " .. message)
    end,

    ---Print info.
    ---@param message string
    info = function(message)
        log.print("INFO: " .. message)
    end,

    ---Print warning.
    ---@param message string
    warning = function(message)
        log.print("WARNING: " .. message)
    end,

    ---Print error.
    ---@param message string
    error = function(message)
        log.print("ERROR: " .. message)
    end,
}
