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

require "src.pods.header"
require "src.pods.log"
require "src.pods.utilities_system"
require "src.pods.utilities"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Init
--
-- ------------------------------------------------------------------------- --

---Generates an initial example recipe and configuration file in the current working directory.
---@param context table Application context defining output paths.
local function mode_init__create(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    local recipe_path = util.build_full_path(".", "recipe", ".lua")
    local config_path = context.config.path or util.build_full_path("config", "", ".lua")

    if system.file_exists(recipe_path) then
        log.error("File '" .. recipe_path .. "' already exists!")
        return
    end

    if system.file_exists(config_path) then
        log.error("File '" .. config_path .. "' already exists!")
        return
    end

    ---@build insert:{"RECIPE_TEMPLATE", "recipe.lua"}
    local recipe_content = {"RECIPE_TEMPLATE"}
    ---@build insert:{"CONFIG_TEMPLATE", "config.lua"}
    local config_content = {"CONFIG_TEMPLATE"}

    if not system.write_file(recipe_path, recipe_content) then
        return
    end
    log.info("Created '" .. recipe_path .. "'.")

    if not system.write_file(config_path, config_content) then
        return
    end
    log.info("Created '" .. config_path .. "'.")
end

---Displays the help text for the init mode, outlining usage, actions, and options.
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

---Handles the init mode, determining whether to display help or create initialization files.
---@param context table Application context containing parsed flags and parameters.
global function mode_init__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.debug("Init mode is used.")
    local action = context.parameters[1] or ""
    if action == "" then
        mode_init__create(context)
        return
    end

    local actions = {
        help = mode_init__help,
    }
    local execute = actions[action] or function()
        log.error("Unknown action: " .. tostring(action))
    end
    execute()
end
