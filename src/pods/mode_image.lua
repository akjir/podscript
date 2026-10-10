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
require "src.pods.utilities_system"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Mode Image
--
-- ------------------------------------------------------------------------- --

---Displays the help text for the image mode, outlining usage, actions, and options.
---@param context table Application context.
local function mode_image__help(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.print("PodScript " .. get_version_string() .. " - Image Mode\n")
    log.print("Manage orphaned and dangling container images.")
    log.print("Usage: pods image [OPTIONS] ACTION")
    log.print("   or: lua pods.lua image [OPTIONS] ACTION\n")
    log.print("ACTIONS:")
    log.print("  prune              prune dangling or all unused images")
    log.print("  help               display this help text\n")
    log.print("OPTIONS:")
    log.print("  --all              prune all unused images, not just dangling ones")
    log.print("  --force            skip confirmation prompt")
    log.print("  --preview          preview images and space that would be deleted")
end

---Handles the pruning of orphaned or dangling images.
---@param context table Application context.
local function mode_image__prune(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    local is_all = context.flags["all"] ~= nil
    local is_force = context.flags["force"] ~= nil
    local is_preview = context.flags["preview"] ~= nil

    if is_preview then
        local filter = is_all and "" or "--filter dangling=true "
        local command = "podman images " .. filter .. "--format \"{{.ID}};;;{{.Repository}};;;{{.Tag}};;;{{.Size}}\""

        local output_lines, success = system.exec_capture(command)
        if not success or output_lines == nil then
            log.error("Failed to query podman images.")
            return
        end

        local total_bytes = 0
        local images_found = false

        if #output_lines == 0 or (#output_lines == 1 and string.is_nil_or_empty(output_lines[1])) then
            log.print("No images found to prune.")
            return
        end

        log.print("Images to be pruned:")

        for i = 1, #output_lines do
            local line = output_lines[i]
            if not string.is_nil_or_empty(line) then
                local parts = string.split(line, ";;;")
                if #parts >= 4 then
                    images_found = true
                    local id = parts[1]
                    local repo = parts[2]
                    local tag = parts[3]
                    local size_str = parts[4]

                    local bytes = util.parse_size_to_bytes(size_str)
                    total_bytes = total_bytes + bytes

                    local display_name = repo
                    if repo == "<none>" then
                        display_name = id
                    elseif tag ~= "<none>" then
                        display_name = repo .. ":" .. tag
                    end

                    log.print(util.format_line("  - " .. display_name, size_str, 60))
                end
            end
        end

        if not images_found then
            log.print("No images found to prune.")
        else
            log.print(string.rep("-", 60))
            log.print(util.format_line("Total space reclaimable:", util.format_bytes(total_bytes), 60))
        end
    else
        local cmd_args = {"podman", "image", "prune", "-f"}
        if is_all then
            table.insert(cmd_args, "-a")
        end
        local cmd = table.concat(cmd_args, " ")

        if not is_force then
            io.write("Are you sure you want to prune " .. (is_all and "all unused" or "dangling") .. " images? Type 'yes' to proceed: ")
            local input = io.read()
            if input ~= "yes" then
                log.print("Aborted.")
                return
            end
        end

        system.exec(cmd, { prefix = "Prune images: ", simulate = context.flags.simulate })
    end
end

---Handles the image mode, parsing arguments to execute the requested action.
---@param context table Application context containing parsed flags and parameters.
global function mode_image__handle(context)
    if type(context) ~= "table" then error("context must be a table", 2) end
    log.debug("Image mode is used.")

    local action = context.parameters[1]

    if string.is_nil_or_empty(action) or action == "help" then
        mode_image__help(context)
        return
    end

    if action == "prune" then
        mode_image__prune(context)
    else
        log.error("Unknown action '" .. tostring(action) .. "' for image mode.")
        mode_image__help(context)
    end
end
