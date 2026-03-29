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
--
--         SECTION Help
--
--
-- ------------------------------------------------------------------------- --

---Print help.
function print_help()
    log.print("PODSCRIPT " .. VERSION)
    log.print("")
    log.print("Usage: pods [OPTIONS] ACTION [TARGETS]")
    log.print("   or: lua pods.lua [OPTIONS] ACTION [TARGETS]")
    log.print("")
    log.print("ACTION:")
    log.print("  create             create a new pod")
    log.print("  recreate           removes and then creates a new pod")
    log.print("  remove             remove a running pod")
    log.print("  update             update all defined images of the pod")
    log.print("")
    log.print("TARGETS:")
    log.print("  *                  names of recipes or groups defined in a config")
    log.print("")
    log.print("OPTIONS:")
    log.print("  --config NAME      use config with given name or path")
    log.print("  --help             display this help and exit")
    log.print("  --simulate         forces simulate mode")
end
