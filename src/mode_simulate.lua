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

require "src.mode_command"
require "src.mode_default"

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Simulate
--
-- ------------------------------------------------------------------------- --

---Handle simulate mode.
---@param registry table
function mode_simulate__handle(registry)
    log.info("Simulate mode is active.")
    registry.flags.simulate = true
    local parameters = registry.parameters
    if parameters[1] == "command" then
        -- remove "command" from parameters
        registry.parameters = table.move(parameters, 2, #parameters, 1, {})
        mode_command__handle(registry)
    else
        mode_default__handle(registry)
    end
end
