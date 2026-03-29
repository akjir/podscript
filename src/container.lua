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

require("helper_print")
require("helper_string")
require("helper_table")
require("helper")

---@build block:
-- ------------------------------------------------------------------------- --
--
--
--         SECTION Container
--
--
-- ------------------------------------------------------------------------- --

---Create a container.
---@param container table
---@param pod table
---@param simulate boolean
function container__create(container, pod, simulate)
    -- main command
    local commands = { "podman run" }

    -- container name
    commands[#commands + 1] = "--name"
    commands[#commands + 1] = container.name

    -- add container to pod
    commands[#commands + 1] = "--pod"
    commands[#commands + 1] = pod.name

    -- detach
    -- default is false
    if container.detach then
        commands[#commands + 1] = "--detach"
    end

    -- container restart
    if not string.is_nil_or_empty(container.restart) then
        commands[#commands + 1] = "--restart"
        commands[#commands + 1] = container.restart
    end

    -- container volumes
    if not table.is_nil_or_empty(container.volumes) then
        for i = 1, #container.volumes do
            local host_dir = container.volumes[i][1]
            local container_dir = container.volumes[i][2]
            local options = container.volumes[i][3]
            if string.is_nil_or_empty(container_dir) then
                print_error("Container dir cannot be empty! (" .. container.name .. ")")
            else
                local command = ""
                if string.is_nil_or_empty(host_dir) then
                    command = container_dir
                else
                    if not string.begins_with(host_dir, "/") then
                        if string.begins_with(host_dir, ".") then
                            host_dir = string.sub(host_dir, 2)
                        end
                        host_dir = build_full_path(pod.path, host_dir, "")
                    end
                    command = host_dir .. ":" .. container_dir
                end
                if not string.is_nil_or_empty(options) then
                    command = command .. ":" .. options
                end
                commands[#commands + 1] = "--volume"
                commands[#commands + 1] = command
            end
        end
    end

    -- container options
    -- if not supported by pods, add them directly to the podman run command
    if not table.is_nil_or_empty(container.options) then
        commands[#commands + 1] = table.concat(container.options, " ")
    end

    -- container image
    local registry = table.get_or_default(container, "registry", pod.registry)
    commands[#commands + 1] = registry .. "/" .. container.image

    -- commands
    -- see: podman run --detach image:tag command
    if not table.is_nil_or_empty(container.commands) then
        commands[#commands + 1] = table.concat(container.commands, " ")
    end

    -- create and execute final podman command
    exec(table.concat(commands, " "), "Create container '" .. container.name .. "': ", simulate)
end

---Ensure container name.
---@param container table
---@param pod_name string
---@param container_alternate_name string
---@return boolean
function container__ensure_name(container, pod_name, container_alternate_name)
    -- container name is optional
    if string.is_nil_or_empty(container.name) then
        container.name = pod_name .. "-" .. container_alternate_name
    else
        container.name = normalize_name(container.name)
        if string.begins_with(container.name, "*") then
            container.name = pod_name .. "-" .. container.name:sub(2)
        end
    end
    return true
end

---Test if container is valid.
---@param container table
---@param pod_name string
---@return boolean
function container__is_valid(container, pod_name)
    if table.is_nil_or_empty(container) then
        print_error("A container in pod '" .. pod_name .. "' is empty!")
        return false
    end

    -- container.name is optional, will be set later

    -- test for container image
    if string.is_nil_or_empty(container.image) then
        print_error("Image not set for container '" .. container.name .. "'!")
        return false
    end

    return true
end

---Stop and removes a container.
---@param container table
---@param simulate boolean
function container__remove(container, simulate)
    exec("podman stop " .. container.name, "Stop container '" .. container.name .. "': ", simulate)
    exec("podman rm " .. container.name, "Remove container '" .. container.name .. "': ", simulate)
end

---Update a container image.
---@param container table
---@param pod table
---@param simulate boolean
function container__update(container, pod, simulate)
    local registry = table.get_or_default(container, "registry", pod.registry)
    print_internal("Update container '" .. container.name .. "' ...")
    exec("podman pull " .. registry .. "/" .. container.image, "", simulate)
end
