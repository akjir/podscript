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

require "src.header"

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Log
--
-- ------------------------------------------------------------------------- --

log = {
    -- Proxy to handle output, defaults to standard print
    print = print,

    ---Print debug message if debug is enabled.
    ---@param message string
    debug = function(message)
        if debug then
            log.print("DEBUG: " .. message)
        end
    end,

    ---Print info message.
    ---@param message string
    info = function(message)
        log.print("INFO: " .. message)
    end,

    ---Print warning message.
    ---@param message string
    warning = function(message)
        log.print("WARNING: " .. message)
    end,

    ---Print error message.
    ---@param message string
    error = function(message)
        log.print("ERROR: " .. message)
    end,
}
