---@build block:
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
---@diagnostic disable: lowercase-global

global<const> *

-- ------------------------------------------------------------------------- --
--
--
--       PODSCRIPT
--
--
-- ------------------------------------------------------------------------- --

---@build const:
global VERSION<const> = "1.4.0"
---@build const:
global BUILD<const> = "dev"

---Get the full version string formatted as 'v<VERSION>+<BUILD>'.
---@return string
global function get_version_string()
    return "v" .. VERSION .. "+" .. BUILD
end
