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
    if string.is_nil_or_empty(command_table.container) and type(command_table.container) ~= "number" then
        log.error("No container in command table set!")
        return false
    end
    if string.is_nil_or_empty(command_table.execute) then
        log.error("No command in command table set!")
        return false
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

    if command_table.user ~= nil then
        commands[#commands + 1] = "-u"
        commands[#commands + 1] = tostring(command_table.user)
    end

    local container_name
    if type(command_table.container) == "number" and recipe.containers[command_table.container] then
        local container = recipe.containers[command_table.container]
        container__ensure_name(container, recipe.pod.name, tostring(command_table.container))
        container_name = container.name
    else
        container_name = tostring(command_table.container)
        container_name = normalize_name(container_name)
        if string.begins_with(container_name, "*") then
            container_name = recipe.pod.name .. "-" .. container_name:sub(2)
        end
    end

    commands[#commands + 1] = container_name
    commands[#commands + 1] = command_table.execute

    system.exec(table.concat(commands, " "),
        "Execute command '" .. command_table.execute .. "' in container '" .. container_name .. "': ",
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
    if table.is_nil_or_empty(recipe.pod.commands) then
        log.print("There are no commands defined in recipe '" .. target .. "'.")
        return
    end

    local sorted_commands = {}
    for command, _ in pairs(recipe.pod.commands) do
        table.insert(sorted_commands, command)
    end
    table.sort(sorted_commands)

    local valid_commands = {}
    for i = 1, #sorted_commands do
        local command = sorted_commands[i]
        local command_table = recipe.pod.commands[command]
        local description = command_table.description
        if string.is_nil_or_empty(description) then
            log.warning("Command '" .. command .. "' has no description.")
        else
            table.insert(valid_commands, { name = command, desc = description })
        end
    end

    if #valid_commands == 0 then
        log.print("There is no valid command in recipe '" .. target .. "'.")
        return
    end

    log.print("Commands for recipe '" .. target .. "':")
    for i = 1, #valid_commands do
        log.print("  " .. valid_commands[i].name .. ": " .. valid_commands[i].desc)
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
            local command_table = nil
            if not table.is_nil_or_empty(recipe.pod.commands) then
                command_table = recipe.pod.commands[command]
            end
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
