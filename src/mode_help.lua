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
require "src.helper_print"

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
    print_internal("PODSCRIPT " .. VERSION)
    print_internal("")
    print_internal("Usage: pods [OPTIONS] ACTION [TARGETS]")
    print_internal("   or: lua pods.lua [OPTIONS] ACTION [TARGETS]")
    print_internal("")
    print_internal("ACTION:")
    print_internal("  create             create a new pod")
    print_internal("  recreate           removes and then creates a new pod")
    print_internal("  remove             remove a running pod")
    print_internal("  update             update all defined images of the pod")
    print_internal("")
    print_internal("TARGETS:")
    print_internal("  *                  names of recipes or groups defined in a config")
    print_internal("")
    print_internal("OPTIONS:")
    print_internal("  --config NAME      use config with given name or path")
    print_internal("  --help             display this help and exit")
    print_internal("  --simulate         forces simulate mode")
end
