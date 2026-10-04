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
---@diagnostic disable: duplicate-set-field

require "src.pods.header"

global<const> *

---@build block:
-- ------------------------------------------------------------------------- --
--
--    SECTION Log
--
-- ------------------------------------------------------------------------- --

global log<const> = {
    -- Debug flag to enable verbose logging
    debug_enabled = false,

    -- Proxy to handle output, defaults to standard print
    print = print,
}

---Outputs a debug-level message if verbose logging is enabled.
---@param ... any The variable arguments to format and print.
function log.debug(... args)
    if log.debug_enabled then
        log.print("DEBUG: " .. log.format_args(...))
    end
end

---Outputs an error-level message.
---@param ... any The variable arguments to format and print.
function log.error(... args)
    log.print("ERROR: " .. log.format_args(...))
end

---Formats variable arguments into a single string separated by spaces.
---@param ... any The variable arguments to format.
---@return string The formatted string.
function log.format_args(... args)
    local count = args.n
    if count == 0 then
        return ""
    elseif count == 1 then
        return tostring(args[1])
    end

    local parts = table.create(count)
    for i = 1, count do
        parts[i] = tostring(args[i])
    end
    return table.concat(parts, " ")
end

---Outputs an info-level message.
---@param ... any The variable arguments to format and print.
function log.info(... args)
    log.print("INFO: " .. log.format_args(...))
end

---Outputs a warning-level message.
---@param ... any The variable arguments to format and print.
function log.warning(... args)
    log.print("WARNING: " .. log.format_args(...))
end
