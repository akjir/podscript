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

global<const> *

local build
local get_git_build_string
local get_git_commit_count
local get_git_commit_hash
local is_git_dirty
local iterate_lines
local process_content

build = function(output_filename, input_filenames, is_release)
    local out_file = io.open(output_filename, "w")
    if not out_file then
        io.stderr:write("Error: Could not open output file: " .. output_filename .. "\n")
        return false
    end

    local annotation = "---@build block:"
    local git_build = get_git_build_string(is_release)
    local state = {
        build_string = (type(git_build) == "string" and git_build ~= "") and git_build or "0.unknown",
        has_emitted_global_const = false,
    }

    for _, filename in ipairs(input_filenames) do
        local path = "src/" .. (filename:match("%.lua$") and filename or filename .. ".lua")
        local in_file = io.open(path, "r")
        if not in_file then
            io.stderr:write("Warning: Could not open file " .. path .. "\n")
        else
            local content = in_file:read("*a")
            in_file:close()

            if not content then
                io.stderr:write("Warning: Could not read file " .. path .. "\n")
            else
                local start_idx = content:find(annotation, 1, true)
                if start_idx then
                    local line_end_idx = content:find("\n", start_idx, true)
                    local block_content = line_end_idx and content:sub(line_end_idx + 1) or ""
                    out_file:write(process_content(block_content, state))
                else
                    io.stderr:write("Warning: Build annotation not found in " .. path .. ". Skipping.\n")
                end
            end
        end
    end

    out_file:close()
    return true
end

get_git_build_string = function(is_release)
    local count = get_git_commit_count() or "0"
    local hash = get_git_commit_hash() or "unknown"
    local suffix = ""
    if not is_release and is_git_dirty() then
        suffix = ".dev"
    end
    return count .. "." .. hash .. suffix
end

get_git_commit_count = function()
    local handle = io.popen("git rev-list --count HEAD 2>/dev/null")
    if not handle then
        return "0"
    end
    local result = handle:read("*a") or ""
    local success = handle:close()
    if not success then
        return "0"
    end
    return result:match("^%s*(%d+)%s*$") or "0"
end

get_git_commit_hash = function()
    local handle = io.popen("git rev-parse --short HEAD 2>/dev/null")
    if not handle then
        return "unknown"
    end
    local result = handle:read("*a") or ""
    local success = handle:close()
    if not success then
        return "unknown"
    end
    return result:match("^%s*(%x+)%s*$") or "unknown"
end

is_git_dirty = function()
    local handle = io.popen("git status --porcelain 2>/dev/null")
    if not handle then
        return false
    end
    local result = handle:read("*a") or ""
    local success = handle:close()
    if not success then
        return false
    end
    return (result:match("^%s*(.-)%s*$") or "") ~= ""
end

iterate_lines = function(content)
    local pos = 1
    local len = #content
    return function()
        if pos > len then
            return nil
        end
        local newline_start, newline_end = content:find("\r?\n", pos)
        local line = ""
        if newline_start then
            line = content:sub(pos, newline_start - 1)
            pos = newline_end + 1
        else
            line = content:sub(pos)
            pos = len + 1
        end
        return line
    end
end

process_content = function(content, state)
    local result = {}
    local is_global = false
    local is_const = false

    for line in iterate_lines(content) do
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
                local name = ""
                local value = ""
                local target, val = trimmed:match("^(.-)%s*=%s*(.*)$")
                if target and val and val:sub(1, 1) ~= "=" then
                    if target:sub(1, 6) == "global" then
                        name = (target:match("<const>") and target:match("^global%s+([%w_]+)%s*<const>$"))
                            or target:match("^global%s+([%w_]+)$")
                            or ""
                    else
                        name = target:match("^([%w_]+)$") or ""
                    end
                    value = val
                end

                if name ~= "" and value ~= "" then
                    local leading_ws = line:match("^(%s*)") or ""
                    local final_val = value
                    if name == "BUILD" and state then
                        local build_str = (type(state.build_string) == "string" and state.build_string ~= "") and state.build_string or "0.unknown"
                        final_val = string.format("%q", build_str)
                    end
                    table.insert(result, leading_ws .. "local " .. name .. " <const> = " .. final_val .. "\n")
                else
                    table.insert(result, line .. "\n")
                end
                is_const = false
            else
                local fn_rest = trimmed:match("^global%s+function%s+([%w_].*)$") or trimmed:match("^function%s+([%w_].*)$")
                if fn_rest then
                    local leading_ws = line:match("^(%s*)") or ""
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
            end
        else
            table.insert(result, line .. "\n")
        end
    end

    local final = table.concat(result)
    -- If original content didn't end with newline, trim the one we added
    if #content > 0 and content:sub(-1) ~= "\n" then
        final = final:sub(1, -2)
    end
    return final
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
    "mode_init",
    "main",
}

-- Sensible check: ensure all files in src/ are in the build list
local handle = io.popen("ls src/*.lua 2>/dev/null")
local src_files = ""
if handle then
    src_files = handle:read("*a") or ""
    handle:close()
end

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
    io.stderr:write("\nWarning: The following files in src/ are not included in the build process:\n")
    for _, file in ipairs(missing) do
        io.stderr:write(" - " .. file .. "\n")
    end
    io.stderr:write("Please add them to the 'files' table in build.lua in the correct order.\n\n")
end

local is_release = false
for _, argument in ipairs(arg or {}) do
    if argument == "--release" or argument == "release" then
        is_release = true
        break
    end
end

local success = build("pods.lua", files, is_release)
if not success then
    os.exit(1)
end

if is_release then
    print("Build complete (release).")
else
    print("Build complete.")
end
