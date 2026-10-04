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

require "src.pods.mode_command"
require "src.pods.mode_connect"
require "src.pods.mode_default"
require "src.pods.mode_logs"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Simulate
--
-- ------------------------------------------------------------------------- --

---Handle simulate mode.
---@param context table
global function mode_simulate__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    log.info("Simulate mode is active.")
    context.flags.simulate = true
    local parameters = context.parameters
    if parameters[1] == "command" then
        -- remove "command" from parameters
        context.parameters = table.sub(parameters, 2)
        mode_command__handle(context)
    elseif parameters[1] == "logs" then
        -- remove "logs" from parameters
        context.parameters = table.sub(parameters, 2)
        mode_logs__handle(context)
    elseif parameters[1] == "connect" then
        -- remove "connect" from parameters
        context.parameters = table.sub(parameters, 2)
        mode_connect__handle(context)
    else
        mode_default__handle(context)
    end
end
