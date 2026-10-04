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

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Config
--
-- ------------------------------------------------------------------------- --

---Edit config.
---@param context table
local function mode_config__edit(context)
    if type(context) ~= "table" then error("context must be a table", 2) end

    local editor = context.config.editor
    if editor == "" then
        log.error("No editor configured.")
        return
    end
    local command = editor .. " " .. string.escape_shell(context.config.path)
    system.exec(command, { simulate = context.flags.simulate, interactive = true })
end
---Print config help.
global function mode_config__help()
    log.print("PodScript " .. get_version_string() .. "\n")
    log.print("Usage: pods config [OPTIONS] ACTION")
    log.print("   or: lua pods.lua config [OPTIONS] ACTION\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output\n")
    log.print("ACTIONS:")
    log.print("  help               display this help and exit")
    log.print("  edit               edit config")
    log.print("  show               show config")
end

---Show config.
---@param context table
local function mode_config__show(context)
    if type(context) ~= "table" then error("context must be a table", 2) end

    local config_path_str = tostring(context.config.path)
    if not string.is_nil_or_empty(context.config.path) then
        config_path_str = system.get_absolute_path(context.config.path)
    end
    log.print("Configuration: " .. config_path_str)
    log.print("")

    log.print("Settings:")
    log.print("  Editor:       " .. tostring(context.config.editor))
    log.print("  Simulate:     " .. tostring(context.config.simulate))
    log.print("")

    log.print("Directories:")

    local dir_entries = {}
    local dir_max = 0

    local pods_path = context.config.pods.path or ""
    local pods_status = "[NOT FOUND]"
    if system.directory_exists(pods_path) then
        pods_status = "[OK]"
    end
    local abs_pods_path = system.get_absolute_path(pods_path)
    local pods_line = string.format("  %-14s%s", "Pods:", abs_pods_path)
    local pods_len = string.visible_length(pods_line)
    if pods_len > dir_max then dir_max = pods_len end
    table.insert(dir_entries, {line = pods_line, status = pods_status})

    local recipes_path = context.config.recipes.path or ""
    local recipes_status = "[NOT FOUND]"
    local recipes_files = system.list_directory(recipes_path, "%.lua$")
    if system.directory_exists(recipes_path) then
        local count = recipes_files and #recipes_files or 0
        recipes_status = string.format("[OK, %d recipes found]", count)
    end
    local abs_recipes_path = system.get_absolute_path(recipes_path)
    local recipes_line = string.format("  %-14s%s", "Recipes:", abs_recipes_path)
    local recipes_len = string.visible_length(recipes_line)
    if recipes_len > dir_max then dir_max = recipes_len end
    table.insert(dir_entries, {line = recipes_line, status = recipes_status})

    local dir_target = math.max(44, dir_max + 1)
    for _, entry in ipairs(dir_entries) do
        log.print(util.format_line(entry.line, entry.status, dir_target))
    end
    log.print("")

    log.print("Groups:")

    local groups = context.config.recipes.groups or {}
    local group_names = {}
    for g, _ in pairs(groups) do
        table.insert(group_names, g)
    end
    table.sort(group_names)

    local referenced_recipes = {}
    local validation_cache = {}
    local missing_recipes = {}

    local print_queue = {}
    local max_len = 0

    for i, g in ipairs(group_names) do
        table.insert(print_queue, { text = "  • " .. g })
        local elements = groups[g]
        for j, el in ipairs(elements) do
            local is_last = (j == #elements)
            local branch = is_last and "└── " or "├── "

            if string.begins_with(el, "@") then
                local subgroup_name = string.sub(el, 2)
                table.insert(print_queue, { text = "    " .. branch .. el })

                local sub_elements = groups[subgroup_name]
                if not sub_elements then
                    table.insert(print_queue, { text = "    " .. (is_last and "    " or "│   ") .. "└── [MISSING GROUP]" })
                else
                    for k, sub_el in ipairs(sub_elements) do
                        local is_sub_last = (k == #sub_elements)
                        local sub_branch = is_sub_last and "└── " or "├── "

                        local status = "[OK]"
                        referenced_recipes[sub_el] = true
                        if validation_cache[sub_el] == nil then
                            local path = util.build_full_path(recipes_path, sub_el, ".lua")
                            validation_cache[sub_el] = system.file_exists(path)
                        end
                        if not validation_cache[sub_el] then
                            status = "[NOT FOUND]"
                            missing_recipes[sub_el] = true
                        end

                        local line = string.format("    %s%s%s", (is_last and "    " or "│   "), sub_branch, sub_el)
                        local len = string.visible_length(line)
                        if len > max_len then max_len = len end
                        table.insert(print_queue, { line = line, status = status })
                    end
                end
            else
                local status = "[OK]"
                referenced_recipes[el] = true
                if validation_cache[el] == nil then
                    local path = util.build_full_path(recipes_path, el, ".lua")
                    validation_cache[el] = system.file_exists(path)
                end
                if not validation_cache[el] then
                    status = "[NOT FOUND]"
                    missing_recipes[el] = true
                end

                local line = string.format("    %s%s", branch, el)
                local len = string.visible_length(line)
                if len > max_len then max_len = len end
                table.insert(print_queue, { line = line, status = status })
            end
        end
        if i < #group_names then
            table.insert(print_queue, { text = "    " })
        end
    end

    local target_column = math.max(44, max_len + 1)
    for _, item in ipairs(print_queue) do
        if item.text then
            log.print(item.text)
        else
            log.print(util.format_line(item.line, item.status, target_column))
        end
    end

    local unreferenced = {}
    if recipes_files then
        for _, file in ipairs(recipes_files) do
            local name = string.gsub(file, "%.lua$", "")
            if not referenced_recipes[name] then
                table.insert(unreferenced, file)
            end
        end
    end

    local missing_list = {}
    for m, _ in pairs(missing_recipes) do table.insert(missing_list, m) end
    table.sort(missing_list)
    table.sort(unreferenced)

    if #missing_list > 0 or #unreferenced > 0 then
        log.print("")
        log.print("Validation Summary:")
        if #missing_list > 0 then
            if #missing_list == 1 then
                log.print("- Recipe file for '" .. missing_list[1] .. "' not found!")
            else
                local formatted = {}
                for i = 1, #missing_list - 1 do
                    table.insert(formatted, "'" .. missing_list[i] .. "'")
                end
                log.print("- Recipe files for " .. table.concat(formatted, ", ") .. " and '" .. missing_list[#missing_list] .. "' not found!")
            end
        end
        if #unreferenced > 0 then
            if #unreferenced == 1 then
                log.print("- Potentially unreferenced recipe file '" .. unreferenced[1] .. "' found!")
            else
                local formatted = {}
                for i = 1, #unreferenced - 1 do
                    table.insert(formatted, "'" .. unreferenced[i] .. "'")
                end
                log.print("- Potentially unreferenced recipe files " .. table.concat(formatted, ", ") .. " and '" .. unreferenced[#unreferenced] .. "' found!")
            end
        end
    end
end

---Handle config mode.
---@param context table
global function mode_config__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end

    log.debug("Config mode is used.")
    local action = context.parameters[1]
    if string.is_nil_or_empty(action) then
        action = "show"
    end
    local actions = {
        help = mode_config__help,
        edit = mode_config__edit,
        show = mode_config__show
    }
    local execute = actions[action] or function()
        log.error("Unknown action: " .. tostring(action))
    end
    execute(context)
end
