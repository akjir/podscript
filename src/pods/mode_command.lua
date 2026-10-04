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
require "src.pods.log"
require "src.pods.utilities"
require "src.pods.recipe"
require "src.pods.utilities_system"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Command
--
-- ------------------------------------------------------------------------- --

---Validates command_table.
local function mode_command__validate(command_table, recipe)
    if type(command_table) ~= "table" then error("command_table must be a table", 2) end
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
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
---@param context table
---@param recipe table
---@param command_table table
local function mode_command__execute(context, recipe, command_table)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    if type(command_table) ~= "table" then error("command_table must be a table", 2) end
    local commands = table.create(8)
    commands[1] = "podman exec -it"

    if command_table.user ~= nil then
        commands[#commands + 1] = "-u"
        commands[#commands + 1] = string.escape_shell(tostring(command_table.user))
    end

    local container_name = recipe__resolve_container_name(recipe, command_table.container)
    if not container_name then
        log.error("Container '" .. tostring(command_table.container) .. "' not found in recipe '" .. recipe.name .. "'.")
        return false
    end

    commands[#commands + 1] = string.escape_shell(container_name)
    commands[#commands + 1] = command_table.execute

    system.exec(table.concat(commands, " "), {
        prefix = "Execute command '" .. command_table.execute .. "' in container '" .. container_name .. "': ",
        simulate = context.flags.simulate
    })
end

---Print command help.
local function mode_command__help(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if context.flags.simulate then
        log.print("PodScript " .. get_version_string() .. " - Command Mode (SIMULATED)\n")
        log.print("Simulate the execution of a command defined in a recipe for a container.")
        log.print("Usage: pods simulate command [OPTIONS] [ACTION] RECIPE [COMMAND|INDEX]")
        log.print("   or: lua pods.lua simulate command [OPTIONS] [ACTION] RECIPE [COMMAND|INDEX]\n")
    else
        log.print("PodScript " .. get_version_string() .. " - Command Mode\n")
        log.print("Execute a command defined in a recipe for a container.")
        log.print("Usage: pods command [OPTIONS] [ACTION] RECIPE [COMMAND|INDEX]")
        log.print("   or: lua pods.lua command [OPTIONS] [ACTION] RECIPE [COMMAND|INDEX]\n")
    end
    log.print("ACTIONS:")
    log.print("  exec               execute a command defined in a recipe (default when COMMAND is provided)")
    log.print("  list               list all valid commands for a recipe (default)")
    log.print("  help               display this help text\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output\n")
    log.print("RECIPE:")
    log.print("  *                  name of the recipe\n")
    log.print("COMMAND|INDEX:")
    log.print("  *                  command by name defined in recipe to execute")
    log.print("  <number>           command by numeric index defined in recipe to execute")
end

---Get a list of valid commands for a recipe.
---@param recipe table
---@param suppress_warnings boolean|nil
---@return table
local function mode_command__get_valid_commands(recipe, suppress_warnings)
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    if table.is_nil_or_empty(recipe.pod.commands) then
        return {}
    end

    local command_count = table.size(recipe.pod.commands)
    local sorted_commands = table.create(command_count)
    for command, _ in pairs(recipe.pod.commands) do
        table.insert(sorted_commands, command)
    end
    table.sort(sorted_commands)

    local valid_commands = table.create(command_count)
    for i = 1, #sorted_commands do
        local command = sorted_commands[i]
        local command_table = recipe.pod.commands[command]
        local description = command_table.description
        if string.is_nil_or_empty(description) then
            if not suppress_warnings then
                log.warning("Command '" .. command .. "' has no description.")
            end
            description = ""
        end
        table.insert(valid_commands, { name = command, desc = description, table = command_table })
    end
    return valid_commands
end

---List all commands for a recipe.
---@param context table
---@param recipe table
---@param target string
local function mode_command__list(context, recipe, target)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    if table.is_nil_or_empty(recipe.pod.commands) then
        log.print("There are no commands defined in recipe '" .. target .. "'.")
        return
    end

    local valid_commands = mode_command__get_valid_commands(recipe)

    if #valid_commands == 0 then
        log.print("There is no valid command in recipe '" .. target .. "'.")
        return
    end

    log.print("Commands for recipe '" .. target .. "':")
    for i = 1, #valid_commands do
        local prefix = i .. ")"
        if #valid_commands > 9 and i < 10 then
            prefix = " " .. prefix
        end
        if string.is_nil_or_empty(valid_commands[i].desc) then
            log.print("  " .. prefix .. " " .. valid_commands[i].name)
        else
            log.print("  " .. prefix .. " " .. valid_commands[i].name .. ": " .. valid_commands[i].desc)
        end
    end
end

---Handle recipe mode.
---@param context table
global function mode_command__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.debug("Command mode is used.")

    local p1 = context.parameters[1]
    local p2 = context.parameters[2]
    local p3 = context.parameters[3]

    if string.is_nil_or_empty(p1) or p1 == "help" then
        mode_command__help(context)
        return
    end

    local action, target, command_name

    if p1 == "list" or p1 == "exec" then
        action = p1
        target = p2
        command_name = p3
    else
        target = p1
        if string.is_nil_or_empty(p2) then
            action = "list"
        else
            action = "exec"
            command_name = p2
        end
    end

    if string.is_nil_or_empty(target) then
        if action == "list" then
            log.error("Missing recipe name for command list.")
        elseif action == "exec" then
            log.error("Missing recipe name for command exec.")
        end
        return
    end

    local recipe = recipe__load(context.config.recipes.path, target)
    if recipe ~= nil and recipe__validate(context, recipe, target) then
        if action == "list" then
            mode_command__list(context, recipe, target)
        elseif action == "exec" then
            if string.is_nil_or_empty(command_name) then
                log.error("Missing command for recipe '" .. target .. "'.")
                return
            end

            local command_table = nil
            local command_num = tonumber(command_name)

            if command_num ~= nil then
                local valid_commands = mode_command__get_valid_commands(recipe, true)
                if command_num > 0 and command_num <= #valid_commands then
                    command_table = valid_commands[command_num].table
                    command_name = valid_commands[command_num].name
                end
            elseif not table.is_nil_or_empty(recipe.pod.commands) then
                command_table = recipe.pod.commands[command_name]
            end

            if command_table == nil then
                log.error("Command '" .. command_name .. "' not found in recipe '" .. target .. "'.")
                return
            end
            if mode_command__validate(command_table, recipe) then
                mode_command__execute(context, recipe, command_table)
            end
        end
    end
end
