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
require "src.log"
require "src.helper"

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Config
--
-- ------------------------------------------------------------------------- --

---Print config help.
function mode_config__help()
    log.print("PODSCRIPT " .. VERSION .. "\n")
    log.print("Usage: pods config [OPTIONS] ACTION [TARGETS]")
    log.print("   or: lua pods.lua config [OPTIONS] ACTION [TARGETS]\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("ACTIONS:")
    log.print("  help               display this help and exit")
end

---Print config.
---@param registry table
local function mode_config__print(registry)
    local yaml_lines = table.to_yaml_lines(registry.config)
    for i = 1, #yaml_lines do
        local prefix = string.format("%3d: ", i)
        log.print(prefix .. yaml_lines[i])
    end
end

---Handle config mode.
---@param registry table
function mode_config__handle(registry)
    local action, targets = parse_action_and_targets_parameters(registry)
    local actions = {
        help = mode_config__help,
        print = mode_config__print
    }
    local execute = actions[action] or function()
        log.error("Unknown action: " .. tostring(action))
    end
    execute(registry)
end
