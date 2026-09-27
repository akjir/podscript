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

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Config
--
-- ------------------------------------------------------------------------- --

---Loads PodScript config. Sets default values if missing.
---Returns false if fails to load a file or no recipes are defined.
---@param context table
---@return boolean
global function config__load_and_set(context)
    local config_path = context.config.path

    local config, error, _ = system.load_lua_file(config_path)
    if config == nil then
        if error ~= nil then
            log.error(error)
        end
        log.error("Couldn't load configuration '" .. config_path .. "'!")
        return false
    end

    -- merge loaded config into context.config
    if config.simulate ~= nil then context.config.simulate = config.simulate end
    if config.editor ~= nil then context.config.editor = config.editor end

    if config.pods then
        if config.pods.path ~= nil then context.config.pods.path = config.pods.path end
        for k, v in pairs(config.pods) do
            if k ~= "path" then context.config.pods[k] = v end
        end
    end

    if config.recipes then
        if config.recipes.path ~= nil then context.config.recipes.path = config.recipes.path end
        if config.recipes.groups ~= nil then context.config.recipes.groups = config.recipes.groups end
        for k, v in pairs(config.recipes) do
            if k ~= "path" and k ~= "groups" then context.config.recipes[k] = v end
        end
    end

    -- set default path for recipes
    if string.is_nil_or_empty(context.config.recipes.path) then
        context.config.recipes.path = "."
    end

    -- check recipe values
    if table.is_nil_or_empty(config.recipes) then
        log.error("No recipes defined in config '" .. config_path .. "'!")
        return false
    else
        if table.is_nil_or_empty(config.recipes.groups) then
            log.error("No recipes groups defined in configuration '" .. config_path .. "'!")
            return false
        end
    end

    return true
end

