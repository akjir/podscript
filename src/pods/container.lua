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

require "src.pods.utilities"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Container
--
-- ------------------------------------------------------------------------- --

---Creates and starts a container within a specified pod using Podman.
---@param container table Container configuration table.
---@param pod table Pod configuration table.
---@param simulate boolean True to simulate the creation command without executing it.
global function container__create(container, pod, simulate)
    if type(container) ~= "table" then error("container must be a table", 2) end
    if type(pod) ~= "table" then error("pod must be a table", 2) end
    -- main command
    local commands = table.create(16)
    commands[1] = "podman run"

    -- container name
    commands[#commands + 1] = "--name"
    commands[#commands + 1] = string.escape_shell(container.name)

    -- add container to pod
    commands[#commands + 1] = "--pod"
    commands[#commands + 1] = string.escape_shell(pod.name)

    -- detach
    -- default is true
    if container.detach ~= false then
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
                log.error("Container dir cannot be empty! (" .. container.name .. ")")
            else
                local command = ""
                if string.is_nil_or_empty(host_dir) then
                    command = container_dir
                else
                    if not string.begins_with(host_dir, "/") then
                        if string.begins_with(host_dir, "./") then
                            host_dir = string.sub(host_dir, 2)
                        end
                        host_dir = util.build_full_path(pod.path, host_dir, "")
                    end
                    command = host_dir .. ":" .. container_dir
                end
                if not string.is_nil_or_empty(options) then
                    command = command .. ":" .. options
                end
                commands[#commands + 1] = "--volume"
                commands[#commands + 1] = string.escape_shell(command)
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
    commands[#commands + 1] = string.escape_shell(registry .. "/" .. container.image)

    -- commands
    -- see: podman run --detach image:tag command
    if not table.is_nil_or_empty(container.commands) then
        for i = 1, #container.commands do
            commands[#commands + 1] = string.escape_shell(container.commands[i])
        end
    end

    -- create and execute final podman command
    system.exec(table.concat(commands, " "), {
        prefix = "Create container '" .. container.name .. "': ",
        simulate = simulate
    })
end

---Ensures a container has a valid name, generating one from the pod name and an alternate if omitted or prefixed with an asterisk.
---@param container table Container configuration table to update.
---@param pod_name string The name of the parent pod.
---@param container_alternate_name string A fallback name to append if the container name is missing.
---@return boolean True upon successful name resolution.
global function container__ensure_name(container, pod_name, container_alternate_name)
    if type(container) ~= "table" then error("container must be a table", 2) end
    -- container name is optional
    if string.is_nil_or_empty(container.name) then
        container.name = pod_name .. "-" .. container_alternate_name
    else
        container.name = util.normalize_name(container.name)
        if string.begins_with(container.name, "*") then
            container.name = pod_name .. "-" .. container.name:sub(2)
        end
    end
    return true
end

---Validates the configuration of a container, verifying required fields like the image.
---@param container table Container configuration table to validate.
---@param pod_name string The name of the parent pod.
---@return boolean True if the container is valid, false otherwise.
global function container__is_valid(container, pod_name)
    if type(container) ~= "table" then error("container must be a table", 2) end
    if table.is_nil_or_empty(container) then
        log.error("A container in pod '" .. pod_name .. "' is empty!")
        return false
    end
    -- test for container image
    if string.is_nil_or_empty(container.image) then
        log.error("Image not set for container '" .. container.name .. "'!")
        return false
    end
    return true
end

---Stops and removes a specified container via Podman.
---@param container table Container configuration table containing the container name.
---@param simulate boolean True to simulate the stop and remove commands without executing them.
global function container__remove(container, simulate)
    if type(container) ~= "table" then error("container must be a table", 2) end
    system.exec("podman stop " .. string.escape_shell(container.name), { prefix = "Stop container '" .. container.name .. "': ", simulate = simulate })
    system.exec("podman rm " .. string.escape_shell(container.name), { prefix = "Remove container '" .. container.name .. "': ", simulate = simulate })
end

---Pulls the latest image for a specified container from its registry using Podman.
---@param container table Container configuration table containing image details.
---@param pod table Pod configuration table used for fallback registry resolution.
---@param simulate boolean True to simulate the pull command without executing it.
global function container__update(container, pod, simulate)
    if type(container) ~= "table" then error("container must be a table", 2) end
    if type(pod) ~= "table" then error("pod must be a table", 2) end
    local registry = table.get_or_default(container, "registry", pod.registry)
    log.print("Update container '" .. container.name .. "' ...")
    system.exec("podman pull " .. string.escape_shell(registry .. "/" .. container.image), { simulate = simulate, interactive = true })
end
