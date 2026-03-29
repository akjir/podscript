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

require "src.helper_print"
require "src.helper_string"
require "src.helper_table"
require "src.helper"
require "src.container"
require "src.pod"

---@build block:
-- ------------------------------------------------------------------------- --
--
--
--         SECTION Recipe
--
--
-- ------------------------------------------------------------------------- --

---Load PodScript recipe.
---@param recipe_path string
---@param recipe_name string
---@return table|nil
function recipe__load(recipe_path, recipe_name)
    local full_path = build_full_path(recipe_path, recipe_name, ".lua")
    local recipe, _ = load_lua_file(full_path)
    if recipe == nil then
        print_error("Couldn't load recipe '" .. full_path .. "'!")
        return nil
    else
        return recipe
    end
end

---Switch correct pod function and test pod values.
---@param recipe table
---@param action string
---@param config table
function recipe__validate_and_handle(recipe, target, action, config)
    -- test for pod config name
    if string.is_nil_or_empty(recipe.name) then
        print_error("No recipe name in recipe '" .. target .. "' set!")
        return
    else
        recipe.name = string.trim(recipe.name)
    end

    -- test for pod section
    if table.is_nil_or_empty(recipe.pod) then
        print_error("Pod section in recipe '" .. target .. "' not defined! or empty")
        return
    end

    -- test for pod name
    -- pod name is optional
    if string.is_nil_or_empty(recipe.pod.name) then
        recipe.pod.name = normalize_name(recipe.name)
    else
        recipe.pod.name = normalize_name(recipe.pod.name)
    end

    -- test for pod registry
    if string.is_nil_or_empty(recipe.pod.registry) then
        print_error("No default registry in recipe '" .. target .. "' set or empty!")
        return
    end

    -- test for valid pod path
    if string.is_nil_or_empty(recipe.pod.path) then
        -- if no pod path set in recipe use default path from config
        if string.is_nil_or_empty(config.pods.path) then
            print_error("No default pod path and pod path in recipe '" .. target .. "' set or empty!")
            return
        else
            -- if pod path not set use default path with pod name as folder name
            local path = build_full_path(config.pods.path, recipe.pod.name, "")
            print_info("No pod path in recipe '" .. target .. "' set. Path '" .. path .. "' used.")
            recipe.pod.path = path
        end
    end

    -- test for container section
    if table.is_nil_or_empty(recipe.containers) then
        print_error("Container section in recipe '" .. target .. "' not defined or empty!")
        return
    end

    -- test if containers are valid
    local pod_name = recipe.pod.name
    for id = 1, #recipe.containers do
        if not container__is_valid(recipe.containers[id], pod_name) then
            return
        end
    end

    -- switch for correct function
    if (action == "update") then
        -- most of the tests above arn't necessary for update
        pod__update(recipe, config.simulate)
        return
    end
    if action == "recreate" then
        pod__recreate(recipe, config.simulate)
        return
    end
    if action == "remove" then
        pod__remove(recipe, config.simulate)
        return
    end
    if action == "create" then
        pod__create(recipe, config.simulate)
        return
    end
end
