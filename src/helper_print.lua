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

require("header")

---@build block:
-- ------------------------------------------------------------------------- --
--
--
--         SECTION Print
--
--
-- ------------------------------------------------------------------------- --

---Print debug.
---@param message string
function print_debug(message)
    print_internal("DEBUG: " .. message)
end

---Print info.
---@param message string
function print_info(message)
    print_internal("INFO: " .. message)
end

---Print warning.
---@param message string
function print_warning(message)
    print_internal("WARNING: " .. message)
end

---Print error.
---@param message string
function print_error(message)
    print_internal("ERROR: " .. message)
end
