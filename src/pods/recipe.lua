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

require "src.pods.utilities"
require "src.pods.container"
require "src.pods.pod"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Recipe
--
-- ------------------------------------------------------------------------- --

---Loads and evaluates a PodScript recipe file, returning the resulting configuration table.
---@param recipe_path string The base directory path containing the recipes.
---@param recipe_name string The specific name of the recipe to load.
---@param suppress_errors boolean|nil True to suppress error logging if the recipe fails to load.
---@return table|nil The loaded recipe table, or nil if an error occurred.
global function recipe__load(recipe_path, recipe_name, suppress_errors)
    local full_path = util.build_full_path(recipe_path, recipe_name, ".lua")
    local recipe, error, _ = system.load_lua_file(full_path)
    if recipe == nil then
        if not suppress_errors then
            if error ~= nil then
                log.error(error)
            end
            log.error("Couldn't load recipe '" .. full_path .. "'!")
        end
        return nil
    else
        return recipe
    end
end

---Validates a loaded recipe, ensuring all required fields, pod properties, and containers are properly configured.
---@param context table Application context providing default configuration values.
---@param recipe table The recipe table to validate and normalize.
---@param file_name string The name of the recipe file (used for error reporting).
---@return boolean True if the recipe is valid, false otherwise.
global function recipe__validate(context, recipe, file_name)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    local config = context.config or {}
    local pods = config.pods or {}
    -- test for pod config name
    if string.is_nil_or_empty(recipe.name) then
        log.error("No recipe name in recipe '" .. file_name .. "' set!")
        return false
    else
        recipe.name = string.trim(recipe.name)
    end

    -- test for pod section
    if table.is_nil_or_empty(recipe.pod) then
        log.error("Pod section in recipe '" .. file_name .. "' not defined! or empty")
        return false
    end

    -- test for pod name
    -- pod name is optional
    if string.is_nil_or_empty(recipe.pod.name) then
        recipe.pod.name = util.normalize_name(recipe.name)
    else
        recipe.pod.name = util.normalize_name(recipe.pod.name)
    end

    -- test for commands
    if table.is_nil_or_empty(recipe.pod.commands) then
        recipe.pod.commands = {}
    end

    -- test for pod registry
    if string.is_nil_or_empty(recipe.pod.registry) then
        log.error("No default registry in recipe '" .. file_name .. "' set or empty!")
        return false
    end

    -- test for valid pod path
    if string.is_nil_or_empty(recipe.pod.path) then
        -- if no pod path set in recipe use default path from config
        if string.is_nil_or_empty(pods.path) then
            log.error("No default pod path and pod path in recipe '" .. file_name .. "' set or empty!")
            return false
        else
            -- if pod path not set use default path with pod name as folder name
            local path = util.build_full_path(pods.path, recipe.pod.name, "")
            log.debug("No pod path in recipe '" .. file_name .. "' set. Path '" .. path .. "' used.")
            recipe.pod.path = path
        end
    end

    -- test for container section
    if table.is_nil_or_empty(recipe.containers) then
        log.error("Container section in recipe '" .. file_name .. "' not defined or empty!")
        return false
    end

    -- test if containers are valid
    local pod_name = recipe.pod.name
    for id = 1, #recipe.containers do
        if not container__is_valid(recipe.containers[id], pod_name) then
            return false
        end
    end
    return true
end

---Resolves a precise container name from a user specification (e.g., numeric index, exact name, or relative *name).
---@param recipe table The recipe containing the container definitions.
---@param container_spec string|number The container identifier to resolve.
---@return string|nil The resolved absolute container name, or nil if not found.
global function recipe__resolve_container_name(recipe, container_spec)
    if type(recipe) ~= "table" then error("recipe must be a table", 2) end
    if type(container_spec) == "number" or tonumber(container_spec) then
        local container_index = tonumber(container_spec)
        if container_index and recipe.containers[container_index] then
            local container = recipe.containers[container_index]
            container__ensure_name(container, recipe.pod.name, tostring(container_index))
            return container.name
        end
    end

    local spec_str = tostring(container_spec)
    local container_name = util.normalize_name(spec_str)
    local alternate_container_name

    if string.begins_with(container_name, "*") then
        container_name = recipe.pod.name .. "-" .. container_name:sub(2)
    else
        alternate_container_name = recipe.pod.name .. "-" .. container_name
    end

    for i, container in ipairs(recipe.containers) do
        container__ensure_name(container, recipe.pod.name, tostring(i))
        if container.name == container_name then
            return container.name
        end
    end

    if alternate_container_name then
        for i, container in ipairs(recipe.containers) do
            container__ensure_name(container, recipe.pod.name, tostring(i))
            if container.name == alternate_container_name then
                return container.name
            end
        end
    end

    return nil
end
