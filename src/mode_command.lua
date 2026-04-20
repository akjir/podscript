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
require "src.utilities"
require "src.recipe"
require "src.system"

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Command
--
-- ------------------------------------------------------------------------- --

---Validates command_table.
local function mode_command__validate(command_table, recipe)
    if string.is_nil_or_empty(command_table.container) then
        log.error("No container in command table set!")
        return
    end
    if string.is_nil_or_empty(command_table.execute) then
        log.error("No command in command table set!")
        return
    end
    -- validate container name : APP *APP and 1
    return true
end

---Build and execute command.
---@param registry table
---@param recipe table
---@param command_table table
local function mode_command__execute(registry, recipe, command_table)
    local commands = { "podman exec -it" }

    system.exec(table.concat(commands, " "),
        "Execute command '" .. command_table.execute .. "' in container '" .. command_table.container .. "': ",
        registry.flags.simulate, false)
end

---Print command help.
local function mode_command__help(registry)
    if registry.flags.simulate then
        log.print("PODSCRIPT " .. VERSION .. " - Command Mode (SIMULATED)\n")
        log.print("Simulate the execution of a command defined in a recipe for a container.")
        log.print("Usage: pods simulate command [OPTIONS] NAME COMMAND")
        log.print("   or: lua pods.lua simulate command [OPTIONS] NAME COMMAND\n")
    else
        log.print("PODSCRIPT " .. VERSION .. " - Command Mode\n")
        log.print("Execute a command defined in a recipe for a container.")
        log.print("Usage: pods command [OPTIONS] NAME COMMAND")
        log.print("   or: lua pods.lua command [OPTIONS] NAME COMMAND\n")
    end
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("NAME:")
    log.print("  *                  name of the recipe")
    log.print("COMMAND:")
    log.print("  *                  command by name defined in recipe to execute")
    log.print("  list               list all commands for a recipe")
end

---List all commands for a recipe.
---@param registry table
---@param recipe table
---@param target string
local function mode_command__list(registry, recipe, target)
    -- print formated - comand name, command, description (optional)
    log.print("Commands for recipe '" .. target .. "':")
    for command, command_table in pairs(recipe.commands) do
        log.print("  " .. command .. ": " .. command_table.execute)
    end
end

---Handle recipe mode.
---@param registry table
function mode_command__handle(registry)
    log.debug("Command mode is used.")
    local name = registry.parameters[1]
    local command = registry.parameters[2]

    if string.is_nil_or_empty(name) or name == "help" then
        mode_command__help(registry)
        return
    end
    name = normalize_name(name)
    local untangled_targets = config__untangle_recipes(registry.config.recipes.groups, { name })
    if untangled_targets == nil then return end
    local target = untangled_targets[1]
    local recipe = recipe__load(registry.config.recipes.path, target)
    if recipe ~= nil and recipe__validate(registry, recipe, target) then
        if command == "list" then
            mode_command__list(registry, recipe, target)
        else
            local command_table = recipe.commands[command]
            if command_table == nil then
                log.error("Command '" .. command .. "' not found in recipe '" .. target .. "'.")
                return
            end
            if mode_command__validate(command_table) then
                mode_command__execute(registry, recipe, command_table)
            end
        end
    end
end
