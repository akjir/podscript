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
require "src.system"
require "src.utilities"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Init
--
-- ------------------------------------------------------------------------- --

---Create initial recipe and config files.
---@param registry table
local function mode_init__create(registry)
    local recipe_path = build_full_path(".", "recipe", ".lua")
    local config_path = registry.config_full_path or build_full_path("config", "", ".lua")

    if system.file_exists(recipe_path) then
        log.error("File '" .. recipe_path .. "' already exists!")
        return
    end

    if system.file_exists(config_path) then
        log.error("File '" .. config_path .. "' already exists!")
        return
    end

    local recipe_content = "return {\n"
        .. "    name = \"Example Pod\",\n"
        .. "    description = \"Example web service pod managed by PodScript.\",\n"
        .. "    pod = {\n"
        .. "        name = \"web-service\",\n"
        .. "        path = \"/pods\",\n"
        .. "        registry = \"docker.io\",\n"
        .. "        publish = {\n"
        .. "            { 8080, 80, \"TCP\" },\n"
        .. "        },\n"
        .. "    },\n"
        .. "    containers = {\n"
        .. "        {\n"
        .. "            name = \"*app\",\n"
        .. "            detach = true,\n"
        .. "            image = \"example:latest\",\n"
        .. "            restart = \"always\",\n"
        .. "        },\n"
        .. "    },\n"
        .. "}\n"
    local config_content = "return {\n"
        .. "    pods = {\n"
        .. "        path = \"/pods\",\n"
        .. "    },\n"
        .. "    recipes = {\n"
        .. "        groups = {\n"
        .. "            all = {\n"
        .. "                \"recipe\",\n"
        .. "            },\n"
        .. "        },\n"
        .. "    },\n"
        .. "}\n"

    if not system.write_file(recipe_path, recipe_content) then
        return
    end
    log.info("Created '" .. recipe_path .. "'.")

    if not system.write_file(config_path, config_content) then
        return
    end
    log.info("Created '" .. config_path .. "'.")
end

---Print init help.
global function mode_init__help()
    log.print("PodScript " .. get_version_string() .. "\n")
    log.print("Usage: pods init [OPTIONS]")
    log.print("   or: lua pods.lua init [OPTIONS]\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output\n")
    log.print("ACTIONS:")
    log.print("  help               display this help and exit")
end

---Handle init mode.
---@param registry table
global function mode_init__handle(registry)
    log.debug("Init mode is used.")
    local action, _ = parse_action_and_targets_parameters(registry)
    if action == "" then
        mode_init__create(registry)
        return
    end

    local actions = {
        help = mode_init__help,
    }
    local execute = actions[action] or function()
        log.error("Unknown action: " .. tostring(action))
    end
    execute(registry)
end
