local build_src = io.open("build.lua", "r"):read("*a")

-- Remove the actual execution part at the bottom
local execution_start = build_src:find("local pods_files =", 1, true)
local modified_src = build_src:sub(1, execution_start - 1)

-- Expose process_content for testing
modified_src = modified_src .. "\nreturn { process_content = process_content }\n"

-- Also, build.lua has 'global<const> *' which is a PodScript/Lua5.5 specific annotation.
-- We might need to mock or strip it if normal lua doesn't support it.
modified_src = modified_src:gsub("global<const> %*", "")

local mock_env = {
    string = string, table = table, ipairs = ipairs, type = type, error = error,
    io = {
        open = function(path, mode)
            if path == "tests/fixtures/dummy.txt" then
                return { read = function() return "DUMMY CONTENT WITH MAGIC % %1 ()" end, close = function() end }
            elseif path == "tests/fixtures/missing.txt" then
                return nil
            end
            return io.open(path, mode)
        end,
        stderr = io.stderr
    }
}
setmetatable(mock_env, {__index = _G})

local chunk, err = load(modified_src, "build_mock", "t", mock_env)
if not chunk then
    error("Failed to load mock build.lua: " .. err)
end
local exports = chunk()
local process_content_fn = exports.process_content

local state = {}
local test_content = [[
---@build block:
---@build insert:{"TPL", "tests/fixtures/dummy.txt"}
local my_str = {"TPL"}
]]
state.active_inserts = {}
local result = process_content_fn(test_content, state)

if not result:find("DUMMY CONTENT WITH MAGIC % %1 ()", 1, true) then
    print("Test 1 Failed: Magic characters were not correctly escaped or content not found.")
    print("Result was:", result)
    os.exit(1)
end

local test_missing = [[
---@build block:
---@build insert:{"TPL", "tests/fixtures/missing.txt"}
]]
state.active_inserts = {}
local success, err = pcall(process_content_fn, test_missing, state)
if success or not err:find("Insert template not found") then
    print("Test 2 Failed: Missing file did not trigger expected early validation error.")
    print("Err was:", err)
    os.exit(1)
end

local test_stacked = [[
---@build block:
---@build insert:{"T1", "tests/fixtures/dummy.txt"}
---@build insert:{"T2", "tests/fixtures/dummy.txt"}
local double = {"T1"} .. {"T2"}
]]
state.active_inserts = {}
local result_stacked = process_content_fn(test_stacked, state)
local expected_stacked = 'local double = "DUMMY CONTENT WITH MAGIC % %1 ()" .. "DUMMY CONTENT WITH MAGIC % %1 ()"\n'
if not result_stacked:find(expected_stacked, 1, true) then
    print("Test 3 Failed: Stacked placeholders did not resolve correctly.")
    print("Result was:", result_stacked)
    os.exit(1)
end

print("build.lua tests passed successfully!")
