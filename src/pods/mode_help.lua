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

require "src.pods.header"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Help
--
-- ------------------------------------------------------------------------- --

---Handles the help mode, outputting global usage, available modes, actions, and options.
---@param context table Application context.
global function mode_help__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.print("PodScript " .. get_version_string() .. "\n")
    log.print("Usage: pods [MODE] [OPTIONS] ACTION [TARGETS]")
    log.print("   or: lua pods.lua [MODE] [OPTIONS] ACTION [TARGETS]\n")
    log.print("MODES:")
    log.print("  *                  default mode")
    log.print("  command            execute a command defined in a recipe")
    log.print("  config             manage and inspect configuration")
    log.print("  connect            connect to a running container with an interactive shell")
    log.print("  help               display this help and exit")
    log.print("  image              manage orphaned and dangling container images")
    log.print("  init               initialize default configuration and recipe")
    log.print("  logs               show or follow logs for a pod or container")
    log.print("  recipe             inspect and edit recipes\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output")
    log.print("  --simulate         preview generated commands without executing them")
    log.print("  --all              include all unmanaged podman containers (status only)\n")
    log.print("Valid in default mode only:\n")
    log.print("ACTIONS:")
    log.print("  create             create a new pod")
    log.print("  recreate           removes and then creates a new pod")
    log.print("  remove             remove a running pod")
    log.print("  status             display status of pods and containers")
    log.print("  update             update all defined images of the pod\n")
    log.print("TARGETS:")
    log.print("  *                  names of recipes or groups defined in a config\n")
    log.print("For more: lua pods.lua [MODE] help")
end
