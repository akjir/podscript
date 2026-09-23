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

local function process_content(content, state)
    local result = {}
    local is_global = false
    local is_const = false
    -- Standard Lua line iteration that handles all line endings
    for line in (content .. "\n"):gmatch("(.-)\r?\n") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed == "---@build global:" then
            is_global = true
            -- Do not insert the annotation line into the result
        elseif trimmed == "---@build const:" then
            is_const = true
            -- Do not insert the annotation line into the result
        elseif trimmed == "global<const> *" or trimmed == "global <const> *" then
            if state and not state.has_emitted_global_const then
                state.has_emitted_global_const = true
                table.insert(result, line .. "\n")
            end
        elseif trimmed ~= "" and not trimmed:match("^%-%-") then
            -- Genuine code line
            if is_const then
                local name, value = trimmed:match("^global%s+([%w_]+)%s*<const>%s*=%s*(.*)$")
                if not name then
                    name, value = trimmed:match("^global%s+([%w_]+)%s*=%s*(.*)$")
                end
                if not name then
                    name, value = trimmed:match("^([%w_]+)%s*=%s*(.*)$")
                end
                if name and value then
                    local leading_ws = line:match("^(%s*)")
                    table.insert(result, leading_ws .. "local " .. name .. " <const> = " .. value .. "\n")
                else
                    table.insert(result, line .. "\n")
                end
                is_const = false
            elseif trimmed:match("^global%s+function%s+[%w_]+") or trimmed:match("^function%s+[%w_]+") then
                local leading_ws = line:match("^(%s*)")
                local fn_rest = trimmed:match("^global%s+function%s+(.*)$") or trimmed:match("^function%s+(.*)$")
                if not is_global then
                    table.insert(result, leading_ws .. "local function " .. fn_rest .. "\n")
                else
                    table.insert(result, leading_ws .. "global function " .. fn_rest .. "\n")
                end
                is_global = false
            else
                table.insert(result, line .. "\n")
                is_global = false
            end
        else
            table.insert(result, line .. "\n")
        end
    end

    local final = table.concat(result)
    -- If original content didn't end with newline, trim the one we added
    if content:sub(-1) ~= "\n" then
        final = final:sub(1, -2)
    end
    return final
end

local function build(output_filename, input_filenames)
    local out_file = io.open(output_filename, "w")
    if not out_file then
        print("Error: Could not open output file: " .. output_filename)
        return false
    end

    local annotation = "---@build block:"
    local state = {
        has_emitted_global_const = false,
    }

    for _, filename in ipairs(input_filenames) do
        local path = "src/" .. (filename:match("%.lua$") and filename or filename .. ".lua")
        local in_file = io.open(path, "r")
        if not in_file then
            print("Warning: Could not open file " .. path)
        else
            local content = in_file:read("*a")
            in_file:close()

            local start_idx = content:find(annotation, 1, true)
            if start_idx then
                local line_end_idx = content:find("\n", start_idx, true)
                local block_content = line_end_idx and content:sub(line_end_idx + 1) or ""
                out_file:write(process_content(block_content, state))
            else
                print("Warning: Build annotation not found in " .. path .. ". Skipping.")
            end
        end
    end

    out_file:close()
    return true
end

local files = {
    "header",
    "log",
    "utilities_string",
    "utilities_table",
    "utilities",
    "system",
    "container",
    "pod",
    "recipe",
    "config",
    "mode_command",
    "mode_recipe",
    "mode_config",
    "mode_default",
    "mode_simulate",
    "mode_help",
    "main",
}

-- Sensible check: ensure all files in src/ are in the build list
local src_files = io.popen("ls src/*.lua"):read("*a")
local missing = {}
for file in src_files:gmatch("src/([%w_]+)%.lua") do
    local found = false
    for _, build_file in ipairs(files) do
        if build_file == file then
            found = true
            break
        end
    end
    if not found then
        table.insert(missing, file)
    end
end

if #missing > 0 then
    print("\nWarning: The following files in src/ are not included in the build process:")
    for _, file in ipairs(missing) do
        print(" - " .. file)
    end
    print("Please add them to the 'files' table in build.lua in the correct order.\n")
end

build("pods.lua", files)
print("Build complete.")
