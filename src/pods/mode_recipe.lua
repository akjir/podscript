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
require "src.pods.recipe"
require "src.pods.utilities"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Recipe
--
-- ------------------------------------------------------------------------- --

---Edit recipe.
---@param context table
---@param name string
local function mode_recipe__edit(context, name)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    local found = name
    if found == nil then return end

    local editor = context.config.editor
    if editor == "" then
        log.error("No editor configured.")
        return
    end

    local recipe_path = context.config.recipes.path
    local full_path = util.build_full_path(recipe_path, name, ".lua")

    local command = editor .. " " .. string.escape_shell(full_path)
    system.exec(command, { simulate = context.flags.simulate, interactive = true })
end

---Print config help.
local function mode_recipe__help()
    log.print("PodScript " .. get_version_string() .. "\n")
    log.print("Usage: pods recipe [OPTIONS] ACTION NAME")
    log.print("   or: lua pods.lua recipe [OPTIONS] ACTION NAME\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output\n")
    log.print("ACTIONS:")
    log.print("  help               display this help and exit")
    log.print("  edit               edit recipe")
    log.print("  list               list all recipes")
    log.print("  show               show recipe\n")
    log.print("NAME:")
    log.print("  *                  name of the recipe")
end

---List recipes defined in config.
---@param context table
local function mode_recipe__list(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    if table.is_nil_or_empty(context.config.recipes) or table.is_nil_or_empty(context.config.recipes.groups) then
        log.print("There are no recipes defined in config.")
        return
    end

    local recipe_map = {}
    local recipe_list = {}

    for _, group_targets in pairs(context.config.recipes.groups) do
        if type(group_targets) == "table" then
            for _, target in ipairs(group_targets) do
                if type(target) == "string" and not string.begins_with(target, "@") then
                    local clean_target = string.trim(target)
                    if clean_target ~= "" and not recipe_map[clean_target] then
                        recipe_map[clean_target] = true
                        recipe_list[#recipe_list + 1] = clean_target
                    end
                end
            end
        end
    end

    if #recipe_list == 0 then
        log.print("There are no recipes defined in config.")
        return
    end

    table.sort(recipe_list)

    log.print("Recipes:")
    for i = 1, #recipe_list do
        local target = recipe_list[i]
        local prefix = i .. ")"
        if #recipe_list > 9 and i < 10 then
            prefix = " " .. prefix
        end

        local recipe = recipe__load(context.config.recipes.path, target, true)
        local recipe_name = ""
        local description = ""

        if type(recipe) == "table" then
            if not string.is_nil_or_empty(recipe.name) then
                recipe_name = string.trim(tostring(recipe.name))
            end
            if not string.is_nil_or_empty(recipe.description) then
                description = string.trim(tostring(recipe.description))
            end
        end

        local entry = target
        if recipe_name ~= "" then
            entry = entry .. " (" .. recipe_name .. ")"
        end
        if description ~= "" then
            entry = entry .. ": " .. description
        end

        log.print("  " .. prefix .. " " .. entry)
    end
end

---Show recipe content.
---@param context table
---@param name string
local function mode_recipe__show(context, name)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    local found = name
    if found == nil then return end

    local recipe_path = context.config.recipes.path
    local full_path = util.build_full_path(recipe_path, name, ".lua")

    local lines = system.read_file_content_by_line(full_path)
    if not lines then return end

    for i = 1, #lines do
        local prefix = string.format("%3d: ", i)
        log.print(prefix .. lines[i])
    end
end

---Handle recipe mode.
---@param context table
global function mode_recipe__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    context.config = context.config or {}
    context.config.pods = context.config.pods or {}
    context.config.recipes = context.config.recipes or {}
    context.flags = context.flags or {}
    context.parameters = context.parameters or {}
    log.debug("Recipe mode is used.")
    local action = context.parameters[1]
    if string.is_nil_or_empty(action) or action == "help" then
        mode_recipe__help()
        return
    end
    if action == "list" then
        mode_recipe__list(context)
        return
    end

    local actions = {
        edit = mode_recipe__edit,
        show = mode_recipe__show
    }
    local execute = actions[action]
    local name = context.parameters[2]

    if execute == nil then
        execute = mode_recipe__show
        name = action
    end

    if string.is_nil_or_empty(name) then
        log.error("No recipe name given.")
        return
    end

    if string.begins_with(name, "@") then
        log.error("Groups are not supported in recipe mode.")
        return
    end

    if string.find(name, "/") then
        log.error("Pod/container targeting is not supported in recipe mode.")
        return
    end

    execute(context, name)
end
