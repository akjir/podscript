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

require "src.pods.config"
require "src.pods.recipe"
require "src.pods.utilities"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Default
--
-- ------------------------------------------------------------------------- --

---Queries Podman and formats the runtime status of managed pods and containers for display.
---@param context table Application context.
---@param targets table Array of recipe names to filter the status output.
global function mode_default__status(context, targets)
    if type(context) ~= "table" then error("context must be a table", 2) end
    if type(targets) ~= "table" then error("targets must be a table", 2) end
    local query_command = 'podman ps -a --format "{{.ID}};;;{{.Image}};;;{{.Command}};;;{{.CreatedAt}};;;{{.Status}};;;{{.Ports}};;;{{.Names}};;;{{.PodName}};;;{{.Restarts}}"'
    local lines = system.exec_capture(query_command)
    if not lines then
        log.error("Failed to query podman status.")
        return
    end

    local podman_containers = {}
    for i = 1, #lines do
        local parts = string.split(lines[i], ";;;")
        if #parts >= 9 then
            podman_containers[#podman_containers + 1] = {
                id = parts[1],
                image = parts[2],
                command = parts[3],
                created = parts[4],
                status = parts[5],
                ports = parts[6],
                names = parts[7],
                pod = parts[8],
                restarts = parts[9]
            }
        end
    end

    local display_containers = {}
    local managed_expected = {}

    local targets_to_resolve = {}
    if not table.is_nil_or_empty(targets) then
        for i = 1, #targets do
            targets_to_resolve[#targets_to_resolve + 1] = targets[i]
        end
    else
        -- resolve all known recipes
        if context.config.recipes and context.config.recipes.groups then
            local recipe_map = {}
            for _, group_targets in pairs(context.config.recipes.groups) do
                if type(group_targets) == "table" then
                    for _, target in ipairs(group_targets) do
                        if type(target) == "string" and not string.begins_with(target, "@") then
                            local clean_target = string.trim(target)
                            if clean_target ~= "" and not recipe_map[clean_target] then
                                recipe_map[clean_target] = true
                                targets_to_resolve[#targets_to_resolve + 1] = clean_target
                            end
                        end
                    end
                end
            end
        end
    end

    for i = 1, #targets_to_resolve do
        local target = targets_to_resolve[i]
        local recipe = recipe__load(context.config.recipes.path, target, true)
        if recipe ~= nil and recipe__validate(context, recipe, target) then
            for id = 1, #recipe.containers do
                local container = recipe.containers[id]
                container__ensure_name(container, recipe.pod.name, tostring(id))
                managed_expected[container.name] = {
                    recipe = target,
                    pod_name = recipe.pod.name
                }
            end
        end
    end

    if not context.flags.all then
        local found_names = {}
        for i = 1, #podman_containers do
            local pc = podman_containers[i]
            if managed_expected[pc.names] then
                display_containers[#display_containers + 1] = pc
                found_names[pc.names] = true
            end
        end

        for expected_name, info in pairs(managed_expected) do
            if not found_names[expected_name] then
                display_containers[#display_containers + 1] = {
                    id = "-",
                    image = "-",
                    command = "-",
                    created = "-",
                    status = "Not Found",
                    ports = "-",
                    names = expected_name,
                    pod = info.pod_name,
                    restarts = "-"
                }
            end
        end
    else
        display_containers = podman_containers
        local found_names = {}
        for i = 1, #podman_containers do
            found_names[podman_containers[i].names] = true
        end

        for expected_name, info in pairs(managed_expected) do
            if not found_names[expected_name] then
                display_containers[#display_containers + 1] = {
                    id = "-",
                    image = "-",
                    command = "-",
                    created = "-",
                    status = "Not Found",
                    ports = "-",
                    names = expected_name,
                    pod = info.pod_name,
                    restarts = "-"
                }
            end
        end
    end

    if #display_containers == 0 then
        log.print("No containers found.")
        return
    end

    table.sort(display_containers, function(a, b)
        if a.pod == b.pod then
            return a.names < b.names
        end
        return a.pod < b.pod
    end)

    local cols = {}
    if context.flags.full then
        cols = { "ID", "POD", "NAMES", "STATUS", "RESTARTS", "CREATED", "IMAGE", "COMMAND", "PORTS" }
    else
        cols = { "ID", "POD", "NAMES", "STATUS", "RESTARTS", "CREATED", "IMAGE" }
    end

    local pad_right = function(str, len)
        str = str or ""
        if #str < len then
            return str .. string.rep(" ", len - #str)
        end
        return str
    end

    local max_lengths = {}
    for i = 1, #cols do
        local col = cols[i]
        max_lengths[col] = #col
    end

    for i = 1, #display_containers do
        local c = display_containers[i]
        for j = 1, #cols do
            local col = cols[j]
            local val = tostring(c[string.lower(col)] or "")
            if #val > max_lengths[col] then
                max_lengths[col] = #val
            end
        end
    end

    local header_line = ""
    for i = 1, #cols do
        local col = cols[i]
        header_line = header_line .. pad_right(col, max_lengths[col])
        if i < #cols then
            header_line = header_line .. "   "
        end
    end
    log.print(header_line)

    for i = 1, #display_containers do
        local c = display_containers[i]
        local row_line = ""
        for j = 1, #cols do
            local col = cols[j]
            local val = tostring(c[string.lower(col)] or "")
            row_line = row_line .. pad_right(val, max_lengths[col])
            if j < #cols then
                row_line = row_line .. "   "
            end
        end
        log.print(row_line)
    end
end

---Displays the help text for the status action within the default mode.
---@param context table Application context.
global function mode_default__status_help(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.print("PodScript " .. get_version_string() .. " - Status\n")
    log.print("Display the runtime status of pods and containers.")
    log.print("Usage: pods status [OPTIONS] [TARGETS]")
    log.print("   or: lua pods.lua status [OPTIONS] [TARGETS]\n")
    log.print("OPTIONS:")
    log.print("  --config=NAME      use config with given name or path")
    log.print("  --debug            enable debug output")
    log.print("  --simulate         preview generated commands without executing them")
    log.print("  --all              include all unmanaged podman containers")
    log.print("  --full             display extended container information (image, command, ports)\n")
    log.print("TARGETS:")
    log.print("  *                  names of recipes or groups to filter (defaults to all managed recipes)")
end
---Handles the default mode, orchestrating lifecycle actions (create, recreate, remove, update) or displaying status.
---@param context table Application context containing parsed flags and parameters.
global function mode_default__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.debug("Default mode is used.")
    local action = context.parameters[1]

    -- validate action
    if string.is_nil_or_empty(action) then
        log.error("No action set.")
        return
    end
    if not table.contains({ "create", "recreate", "remove", "update", "status" }, action) then
        log.error("Unknown action '" .. action .. "'.")
        return
    end

    local targets = table.sub(context.parameters, 2)

    -- validate targets
    if table.is_nil_or_empty(targets) and action ~= "status" then
        log.error("No targets set.")
        return
    end

    if action == "status" then
        if not table.is_nil_or_empty(targets) and targets[1] == "help" then
            mode_default__status_help(context)
        else
            mode_default__status(context, targets)
        end
        return
    end

    local untangled_targets = config__untangle(context, targets)
    if not untangled_targets then return end

    -- handle recipes
    local recipe_path = context.config.recipes.path
    local pod_actions = {
        create   = pod__create,
        recreate = pod__recreate,
        remove   = pod__remove,
        update   = pod__update,
    }
    for i = 1, #untangled_targets do
        local target = untangled_targets[i]
        -- load recipe
        local recipe = recipe__load(recipe_path, target)
        -- handle recipe
        if recipe ~= nil and recipe__validate(context, recipe, target) then
            --action is valid at this point
            pod_actions[action](recipe, context.flags.simulate)
        end
    end
end
