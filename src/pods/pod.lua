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

global <const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Pod
--
-- ------------------------------------------------------------------------- --

---Create pod and containers.
---@param recipe table
---@param simulate boolean
global function pod__create(recipe, simulate)
    local commands = table.create(8)
    commands[1] = "podman pod create"

    -- pod name
    commands[#commands + 1] = "--name"
    commands[#commands + 1] = string.escape_shell(recipe.pod.name)

    -- pod publish
    if not table.is_nil_or_empty(recipe.pod.publish) then
        local publish = recipe.pod.publish
        for _, entry in pairs(publish) do
            local size = table.size(entry)
            if size == 1 then
                commands[#commands + 1] = "--publish " .. entry[1]
            elseif size == 2 then
                local e1 = entry[1]
                local e2 = entry[2]
                if e1 == "" then
                    commands[#commands + 1] = "--publish " .. e2
                elseif e2 == "TCP" or e2 == "UDP" then
                    commands[#commands + 1] = "--publish " .. e1 .. "/" .. e2
                else
                    commands[#commands + 1] = "--publish " .. e1 .. ":" .. e2
                end
            elseif size > 2 then
                commands[#commands + 1] = "--publish " .. entry[1] .. ":" .. entry[2] .. "/" .. entry[3]
            end
        end
    end

    -- pod options
    -- if not supported by pods, add them directly to the podman run command
    if not table.is_nil_or_empty(recipe.pod.options) then
        commands[#commands + 1] = table.concat(recipe.pod.options, " ")
    end

    -- create pod
    system.exec(table.concat(commands, " "), "Create pod '" .. recipe.name .. "' ('" .. recipe.pod.name .. "'): ",
        simulate, false)

    -- create containers
    local containers = recipe.containers
    for id = 1, #containers do
        local container = containers[id]
        container__ensure_name(container, recipe.pod.name, tostring(id))
        container__create(container, recipe.pod, simulate)
    end
end

---Remove pod and containers.
---@param recipe table
---@param simulate boolean
global function pod__remove(recipe, simulate)
    -- remove containers
    local containers = recipe.containers
    for id = #containers, 1, -1 do -- reverse order when shutting down containers
        local container = containers[id]
        container__ensure_name(container, recipe.pod.name, tostring(id))
        container__remove(container, simulate)
    end

    -- remove pod
    system.exec("podman pod rm " .. string.escape_shell(recipe.pod.name), "Remove pod '" .. recipe.name .. "' ('" .. recipe.pod.name .. "'): ",
        simulate, false)
end

---Remove and create pod and containers.
---@param recipe table
---@param simulate boolean
global function pod__recreate(recipe, simulate)
    pod__remove(recipe, simulate)
    pod__create(recipe, simulate)
end

---Update containers of the pod.
---@param recipe table
---@param simulate boolean
global function pod__update(recipe, simulate)
    log.print("Update pod '" .. recipe.name .. "' ('" .. recipe.pod.name .. "') ...")
    local containers = recipe.containers

    -- update containers
    for id = 1, #containers do
        local container = containers[id]
        container__ensure_name(container, recipe.pod.name, tostring(id))
        container__update(containers[id], recipe.pod, simulate)
    end
end

---Print status of containers.
---@param context table
global function pod__status(context)
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
    if not table.is_nil_or_empty(context.targets) then
        for i = 1, #context.targets do
            targets_to_resolve[#targets_to_resolve + 1] = context.targets[i]
        end
    elseif not context.flags.all then
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

        if not table.is_nil_or_empty(context.targets) then
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
        cols = { "ID", "POD", "NAMES", "STATUS", "RESTARTS", "CREATED" }
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
