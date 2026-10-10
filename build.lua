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

--------------------------------------------------------------------------------
-- I/O Helpers
--------------------------------------------------------------------------------

---Reads the entire content of a file.
---@param path string
---@return string|nil
local function read_file(path)
    if type(path) ~= "string" then error("path must be a string", 2) end
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

---Writes the given content to a file.
---@param path string
---@param content string
---@return boolean
local function write_file(path, content)
    if type(path) ~= "string" then error("path must be a string", 2) end
    if type(content) ~= "string" then error("content must be a string", 2) end
    local file = io.open(path, "w")
    if not file then
        return false
    end
    file:write(content)
    file:close()
    return true
end

--------------------------------------------------------------------------------
-- Git Info
--------------------------------------------------------------------------------

---Gets the total commit count for the current branch.
---@return string
local function get_git_commit_count()
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

---Gets the short commit hash for the current HEAD.
---@return string
local function get_git_commit_hash()
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

---Checks if the git working directory is dirty.
---@return boolean
local function is_git_dirty()
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

---Generates the full build string for the current git state.
---@param is_release boolean
---@return string
local function get_git_build_string(is_release)
    if type(is_release) ~= "boolean" then error("is_release must be a boolean", 2) end
    local count = get_git_commit_count() or "0"
    local hash = get_git_commit_hash() or "unknown"
    local suffix = ""
    if not is_release and is_git_dirty() then
        suffix = ".dev"
    end
    return count .. "." .. hash .. suffix
end

--------------------------------------------------------------------------------
-- Code Processing
--------------------------------------------------------------------------------

---Returns an iterator over the lines in the given string content.
---@param content string
---@return function
local function iterate_lines(content)
    if type(content) ~= "string" then error("content must be a string", 2) end
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

---Processes raw lua content based on build annotations.
---@param content string
---@param state table
---@return string
local function process_content(content, state)
    if type(content) ~= "string" then error("content must be a string", 2) end
    if type(state) ~= "table" then error("state must be a table", 2) end

    local result = {}
    local is_global = false
    local is_const = false

    for line in iterate_lines(content) do
        local current_line = line
        if state.active_inserts and #state.active_inserts > 0 then
            for _, insert_info in ipairs(state.active_inserts) do
                local escaped_placeholder = insert_info.placeholder:gsub("[%^$()%%.%[%]*+%-?]", "%%%1")
                current_line = current_line:gsub(escaped_placeholder, function() return insert_info.replacement end)
            end
        end

        local trimmed = current_line:match("^%s*(.-)%s*$")
        local insert_placeholder, insert_path = trimmed:match("^%-%-%-@build%s+insert:%s*{%s*\"([^\"]+)\"%s*,%s*\"([^\"]+)\"%s*}$")

        if insert_placeholder and insert_path then
            local file_content = read_file(insert_path)
            if not file_content then
                error("Build failed: Insert template not found at '" .. insert_path .. "'")
            end
            local formatted_content = string.format("%q", file_content)

            if not state.active_inserts then state.active_inserts = {} end
            table.insert(state.active_inserts, {
                placeholder = '{"' .. insert_placeholder .. '"}',
                replacement = formatted_content
            })
            -- Do not insert the annotation line into the result
        elseif trimmed == "---@build global:" then
            is_global = true
            -- Do not insert the annotation line into the result
        elseif trimmed == "---@build const:" then
            is_const = true
            -- Do not insert the annotation line into the result
        elseif trimmed == "global<const> *" then
            if not state.has_emitted_global_const then
                state.has_emitted_global_const = true
                table.insert(result, current_line .. "\n")
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
                    local leading_ws = current_line:match("^(%s*)") or ""
                    local final_val = value
                    if name == "BUILD" then
                        local build_str = (type(state.build_string) == "string" and state.build_string ~= "") and state.build_string or "0.unknown"
                        final_val = string.format("%q", build_str)
                    end
                    table.insert(result, leading_ws .. "local " .. name .. " <const> = " .. final_val .. "\n")
                else
                    table.insert(result, current_line .. "\n")
                end
                is_const = false
            else
                local fn_rest = trimmed:match("^global%s+function%s+([%w_.:].*)$") or trimmed:match("^function%s+([%w_.:].*)$")
                if fn_rest then
                    local leading_ws = current_line:match("^(%s*)") or ""
                    if not is_global then
                        if string.find(fn_rest, "[.:]") then
                            table.insert(result, leading_ws .. "function " .. fn_rest .. "\n")
                        else
                            table.insert(result, leading_ws .. "local function " .. fn_rest .. "\n")
                        end
                    else
                        table.insert(result, leading_ws .. "global function " .. fn_rest .. "\n")
                    end
                    is_global = false
                else
                    table.insert(result, current_line .. "\n")
                    is_global = false
                end
            end
        else
            table.insert(result, current_line .. "\n")
        end
    end

    local final = table.concat(result)
    -- If original content didn't end with newline, trim the one we added
    if #content > 0 and content:sub(-1) ~= "\n" then
        final = final:sub(1, -2)
    end
    return final
end

--------------------------------------------------------------------------------
-- Build Execution
--------------------------------------------------------------------------------

---Checks for missing files in a source directory by comparing it with expected files.
---@param source_dir string
---@param expected_files table
local function check_missing_files(source_dir, expected_files)
    if type(source_dir) ~= "string" then error("source_dir must be a string", 2) end
    if type(expected_files) ~= "table" then error("expected_files must be a table", 2) end

    local safe_dir = "'" .. source_dir:gsub("'", "'\\''") .. "'"
    local handle = io.popen("ls -1 " .. safe_dir .. " 2>/dev/null")
    if not handle then
        return
    end

    local src_files_output = handle:read("*a") or ""
    handle:close()

    local missing = {}
    for line in src_files_output:gmatch("[^\r\n]+") do
        if string.match(line, "%.lua$") then
            local file_base = string.match(line, "^([^%.]+)%.lua$")
            if file_base then
                local found = false
                for _, build_file in ipairs(expected_files) do
                    if build_file == file_base then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(missing, file_base .. ".lua")
                end
            end
        end
    end

    if #missing > 0 then
        io.stderr:write("\nWarning: The following files in " .. source_dir .. "/ are not included in the build process:\n")
        for _, file in ipairs(missing) do
            io.stderr:write(" - " .. file .. "\n")
        end
        io.stderr:write("Please add them to the 'files' table in build.lua in the correct order.\n\n")
    end
end

---Builds the PodScript target by combining and parsing source files.
---@param output_filename string
---@param source_dir string
---@param input_filenames table
---@param is_release boolean
---@return boolean
local function build(output_filename, source_dir, input_filenames, is_release)
    if type(output_filename) ~= "string" then error("output_filename must be a string", 2) end
    if type(source_dir) ~= "string" then error("source_dir must be a string", 2) end
    if type(input_filenames) ~= "table" then error("input_filenames must be a table", 2) end
    if type(is_release) ~= "boolean" then error("is_release must be a boolean", 2) end

    local annotation = "---@build block:"
    local git_build = get_git_build_string(is_release)
    local state = {
        build_string = (type(git_build) == "string" and git_build ~= "") and git_build or "0.unknown",
        has_emitted_global_const = false,
        active_inserts = {},
    }

    local final_output = {}

    for _, filename in ipairs(input_filenames) do
        local path = source_dir .. "/" .. (filename:match("%.lua$") and filename or filename .. ".lua")
        local content = read_file(path)

        if not content then
            io.stderr:write("Warning: Could not read file " .. path .. "\n")
        else
            state.active_inserts = {}
            local start_idx = content:find(annotation, 1, true)
            if start_idx then
                local line_end_idx = content:find("\n", start_idx, true)
                local block_content = line_end_idx and content:sub(line_end_idx + 1) or ""
                table.insert(final_output, process_content(block_content, state))
            else
                io.stderr:write("Warning: Build annotation not found in " .. path .. ". Skipping.\n")
            end
        end
    end

    local result_content = table.concat(final_output)
    local success = write_file(output_filename, result_content)
    if not success then
        io.stderr:write("Error: Could not write output file: " .. output_filename .. "\n")
        return false
    end

    return true
end

--------------------------------------------------------------------------------
-- Main Entrypoint
--------------------------------------------------------------------------------

local pods_files = {
    "header",
    "log",
    "utilities_string",
    "utilities_table",
    "utilities",
    "utilities_system",
    "container",
    "recipe",
    "pod",
    "config",
    "mode_command",
    "mode_connect",
    "mode_recipe",
    "mode_config",
    "mode_default",
    "mode_logs",
    "mode_image",
    "mode_init",
    "main",
}

local pods_converter_files = {}

check_missing_files("src/pods", pods_files)
check_missing_files("src/pods-converter", pods_converter_files)

local is_release = false
for _, argument in ipairs(arg or {}) do
    if argument == "--release" or argument == "release" then
        is_release = true
        break
    end
end

local success = build("pods.lua", "src/pods", pods_files, is_release)
if not success then
    os.exit(1)
end

if #pods_converter_files > 0 then
    local success_conv = build("pods-converter.lua", "src/pods-converter", pods_converter_files, is_release)
    if not success_conv then
        os.exit(1)
    end
end

if is_release then
    print("Build complete (release).")
else
    print("Build complete.")
end
