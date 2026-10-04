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

global<const> *

-- ------------------------------------------------------------------------- --
--   PODSCRIPT TEST
-- ------------------------------------------------------------------------- --

require "tests.pods.test_utilities"

local output_stack = {}
local single_test_name = ""
local tests_count = 0
local tests_count_failed = 0
local test_release = true
local use_json = false
local fail_fast = false
local start_time = os.clock()
local failure_summaries = {}
local test_report = { tests = {} }

--- set mode and complete print
if #arg ~= 0 then
    for i = 1, #arg do
        local argument = arg[i]
        if argument == "--dev" then
            test_release = false
        elseif argument == "--json" then
            use_json = true
        elseif argument == "--fail-fast" then
            fail_fast = true
        elseif single_test_name == "" then
            single_test_name = argument
        end
    end
end

-- Suppress prints when use_json is true
local original_print = print
local function controlled_print(...)
    if not use_json then
        original_print(...)
    end
end
local print = controlled_print

if test_release then
    require "pods"
else
    require "src.pods.main"
end

---Print function
---@param ... any
local function print_to_stack(...args)
    local caller_info = ""
    for i = 2, 6 do
        local info = debug.getinfo(i, "Sl")
        if info then
            local short_src = info.short_src
            if short_src and not string.find(short_src, "log.lua", 1, true) and not string.find(short_src, "test.lua", 1, true) then
                local filename = string.match(short_src, "([^/\\]+)$") or short_src
                caller_info = "[" .. filename .. ":" .. tostring(info.currentline) .. "] "
                break
            end
        end
    end

    local line = ""
    if args.n <= 1 then
        line = tostring(args[1] or "")
    else
        local parts = table.create(args.n)
        for i = 1, args.n do
            parts[i] = tostring(args[i])
        end
        line = table.concat(parts, "\t")
    end
    output_stack[#output_stack + 1] = caller_info .. line
end

-- global function for capture output
log.print = print_to_stack

-- set debug flag in pods.lua
log.debug_enabled = true

local function print_full_stack(stack)
    print()
    print("Stack:")
    for i = 1, #stack do
        local line = ""
        if i > 9 then line = tostring(i) else line = " " .. tostring(i) end
        print("  " .. line .. ": " .. stack[i])
    end
    print()
end

local function escape_json(str)
    str = string.gsub(str, '\\', '\\\\')
    str = string.gsub(str, '"', '\\"')
    str = string.gsub(str, '\n', '\\n')
    str = string.gsub(str, '\r', '\\r')
    str = string.gsub(str, '\t', '\\t')
    str = string.gsub(str, "[%z\1-\31]", function(c)
        return string.format("\\u%04x", string.byte(c))
    end)
    return str
end

local function print_json_report()
    local out = {}
    table.insert(out, '{\n  "summary": {\n')
    table.insert(out, '    "total": ' .. tests_count .. ',\n')
    table.insert(out, '    "failed": ' .. tests_count_failed .. ',\n')
    table.insert(out, '    "time_seconds": ' .. string.format("%.2f", os.clock() - start_time) .. '\n  },\n')
    table.insert(out, '  "failures": {\n')

    local first = true
    for msg, count in pairs(failure_summaries) do
        if not first then table.insert(out, ',\n') else first = false end
        table.insert(out, '    "' .. escape_json(msg) .. '": ' .. count)
    end
    if not first then table.insert(out, '\n') end
    table.insert(out, '  },\n  "tests": [\n')

    first = true
    for _, t in ipairs(test_report.tests) do
        if not first then table.insert(out, ',\n') else first = false end
        table.insert(out, '    {\n      "name": "' .. escape_json(t.name) .. '",\n')
        table.insert(out, '      "status": "' .. t.status .. '"')
        if t.errors and #t.errors > 0 then
            table.insert(out, ',\n      "errors": [\n')
            local first_err = true
            for _, err in ipairs(t.errors) do
                if not first_err then table.insert(out, ',\n') else first_err = false end
                table.insert(out, '        "' .. escape_json(err) .. '"')
            end
            table.insert(out, '\n      ]')
        end
        table.insert(out, '\n    }')
    end
    table.insert(out, '\n  ]\n}')
    original_print(table.concat(out))
end

local function evaluate_assertions(expectations, errors, custom_stack)
    local stack = custom_stack or output_stack
    if expectations.contains then
        for _, expected in ipairs(expectations.contains) do
            local found = false
            for _, line in ipairs(stack) do
                if string.find(line, expected, 1, true) then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(errors, "Missing 'contains': " .. expected)
            end
        end
    end

    if expectations.sequence then
        local current_idx = 1
        for _, expected in ipairs(expectations.sequence) do
            local found = false
            for i = current_idx, #stack do
                if string.find(stack[i], expected, 1, true) then
                    found = true
                    current_idx = i + 1
                    break
                end
            end
            if not found then
                table.insert(errors, "Missing in sequence: '" .. expected .. "'")
            end
        end
    end

    if expectations.not_contains then
        for _, not_expected in ipairs(expectations.not_contains) do
            for _, line in ipairs(stack) do
                if string.find(line, not_expected, 1, true) then
                    table.insert(errors, "Found 'not_contains': " .. not_expected)
                    break
                end
            end
        end
    end

    if expectations.matches then
        for _, pattern in ipairs(expectations.matches) do
            local found = false
            for _, line in ipairs(stack) do
                if string.find(line, pattern, 1, false) then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(errors, "Missing 'matches': " .. pattern)
            end
        end
    end

    if expectations.count then
        for expected_str, expected_count in pairs(expectations.count) do
            local count = 0
            for _, line in ipairs(stack) do
                if string.find(line, expected_str, 1, true) then
                    count = count + 1
                end
            end
            if count ~= expected_count then
                table.insert(errors,
                    "Count mismatch for '" .. expected_str .. "': expected " .. expected_count .. ", found " .. count)
            end
        end
    end
end

_G.__TEST_FRAMEWORK = {
    evaluate_assertions = evaluate_assertions
}

-- ------------------------------------------------------------------------- --
--      Execute Tests
-- ------------------------------------------------------------------------- --

local function execute_mode_test(default_config_name, test_code, test_table, print_stack)
    output_stack = {}
    local config_name = table.get_or_default(test_table, "config", "")
    local arguments = {}

    if config_name == "" then
        if default_config_name ~= "" then
            local config_argument = "--config=" .. "tests/pods/configs/" .. default_config_name
            table.insert(arguments, config_argument)
        end
    else
        local config_argument = "--config=" .. "tests/pods/configs/" .. config_name
        table.insert(arguments, config_argument)
    end

    if test_table.help then
        table.insert(arguments, "help")
    end

    if test_table.simulate then
        table.insert(arguments, "simulate")
    end
    table.append(arguments, test_table.parameters)

    -- execute pods or src.main with arguments
    local errors = {}
    local success, err_msg = pcall(main, arguments)
    if not success then
        table.insert(errors, "Crash during execution: " .. tostring(err_msg))
    end
    local expectations = test_table.expectations or {}

    evaluate_assertions(expectations, errors)

    if #errors > 0 then
        local description = test_table.description
        if not use_json then
            print("## Test '" .. test_code .. "' failed.")
            if not string.is_nil_or_empty(description) then
                print(" Description: " .. test_table.description)
            end
            print(" Call: lua pods.lua " .. table.concat(arguments, " "))
            print()
            for _, err in ipairs(errors) do
                print("  Error: " .. err)
            end
            if print_stack then print_full_stack(output_stack) else print() end
        end
        for _, err in ipairs(errors) do
            failure_summaries[err] = (failure_summaries[err] or 0) + 1
        end
        table.insert(test_report.tests, { name = test_code, status = "failed", errors = errors })
        output_stack = {}
        return false
    end
    table.insert(test_report.tests, { name = test_code, status = "passed" })
    output_stack = {}
    return true
end

---Executes a unit test. Test has to have a run() function and an expected value, and optionally expectations.
---@param test_code string
---@param test_table table
local function execute_unit_test(test_code, test_table, print_stack)
    output_stack = {}
    local args = test_table.args or {}
    local success, result = pcall(function()
        if test_table.args then
            return test_table.run(table.unpack(test_table.args))
        else
            return test_table.run()
        end
    end)

    local errors = {}

    if not success then
        table.insert(errors, "Crash during execution: " .. tostring(result))
    else
        if test_table.expected ~= nil and result ~= test_table.expected then
            table.insert(errors,
                "Return value mismatch: Expected '" ..
                tostring(test_table.expected) .. "', got '" .. tostring(result) .. "'")
        end
    end

    local expectations = test_table.expectations or {}
    evaluate_assertions(expectations, errors)

    if #errors > 0 then
        local description = test_table.description
        if not use_json then
            print("## Test '" .. test_code .. "' failed.")
            if not string.is_nil_or_empty(description) then
                print(" Description: " .. test_table.description)
            end
            print()
            for _, err in ipairs(errors) do
                print("  Error: " .. err)
            end
            if test_table.expected ~= nil then
                print("  Result:   '" .. tostring(result) .. "'")
                print("  Expected: '" .. tostring(test_table.expected) .. "'")
            end
            if print_stack then print_full_stack(output_stack) else print() end
        end
        for _, err in ipairs(errors) do
            failure_summaries[err] = (failure_summaries[err] or 0) + 1
        end
        table.insert(test_report.tests, { name = test_code, status = "failed", errors = errors })
        output_stack = {}
        return false
    end
    table.insert(test_report.tests, { name = test_code, status = "passed" })
    output_stack = {}
    return true
end

local function execute_test(default_config_name, test_code, test_table, print_stack)
    if test_table.run ~= nil then
        if not execute_unit_test(test_code, test_table, print_stack) then
            tests_count_failed = tests_count_failed + 1
        end
    else
        if not execute_mode_test(default_config_name, test_code, test_table, print_stack) then
            tests_count_failed = tests_count_failed + 1
        end
    end
end

local function execute_test_suite(test_suite)
    local tests = test_suite.tests
    for test_code, test_table in pairs(tests) do
        if not (test_release and test_table.dev_only) then
            local default_config_name = table.get_or_default(test_suite, "config", "")
            tests_count = tests_count + 1
            execute_test(default_config_name, test_code, test_table, false)
            if fail_fast and tests_count_failed > 0 then
                break
            end
        end
    end
end

-- ------------------------------------------------------------------------- --
--      Test Suites
-- ------------------------------------------------------------------------- --

local test_suites = {}

local function add_suite(name)
    local suite = require("tests." .. name)
    table.insert(test_suites, suite)
end

add_suite("pods.suite_001_argument_options")
add_suite("pods.suite_002_utilities_string")
add_suite("pods.suite_003_utilities_table")
add_suite("pods.suite_004_actions")
add_suite("pods.suite_005_targets")
add_suite("pods.suite_006_recipes")
add_suite("pods.suite_007_pods")
add_suite("pods.suite_008_containers")
add_suite("pods.suite_009_utilities_system")
add_suite("pods.suite_010_utilities")
add_suite("pods.suite_011_mode_config")
add_suite("pods.suite_012_mode_recipe")
add_suite("pods.suite_013_mode_command")
add_suite("pods.suite_014_globals")
add_suite("pods.suite_015_varargs")
add_suite("pods.suite_016_mode_init")
add_suite("pods.suite_017_action_status")
add_suite("pods.suite_018_release_integration")
add_suite("pods.suite_019_mode_logs")
add_suite("pods.suite_020_mode_connect")
add_suite("pods.suite_999_test_framework")

-- ------------------------------------------------------------------------- --
--      Main
-- ------------------------------------------------------------------------- --

local found = false -- define here to prevent "Test failed." if no test was found
if test_release then
    print("Running tests in release mode.")
else
    print("Running tests in development mode.")
end
if single_test_name == "" then
    if test_release then
        print("Some tests can only be run in development mode.")
    end
    found = true
    for _, test_suite in ipairs(test_suites) do
        execute_test_suite(test_suite)
        if fail_fast and tests_count_failed > 0 then
            break
        end
    end
else
    local run_count = 0
    for _, test_suite in ipairs(test_suites) do
        -- Check if it matches a suite number
        if test_suite.suite == single_test_name then
            if test_release then
                print("Some tests can only be run in development mode.")
            end
            found = true
            for test_code, test_table in pairs(test_suite.tests) do
                if not (test_release and test_table.dev_only) then
                    local default_config_name = table.get_or_default(test_suite, "config", "")
                    execute_test(default_config_name, test_code, test_table, true)
                    run_count = run_count + 1
                    if fail_fast and tests_count_failed > 0 then
                        break
                    end
                end
            end
            if fail_fast and tests_count_failed > 0 then
                break
            end
        else
            -- Check individual tests by code
            local default_config_name = table.get_or_default(test_suite, "config", "")
            for test_code, test_table in pairs(test_suite.tests) do
                if test_code == single_test_name then
                    found = true
                    if test_release and test_table.dev_only then
                        print("Test '" .. test_code .. "' can only be used in development mode.")
                    else
                        execute_test(default_config_name, test_code, test_table, true)
                        run_count = run_count + 1
                    end
                end
            end
        end
    end

    tests_count = run_count
    if not found then
        print("Test or suite '" .. single_test_name .. "' not found.")
        tests_count_failed = 1
        tests_count = 1
    end
end

if tests_count_failed == 0 then
    if tests_count == 1 then
        print("Test passed.")
    else
        print(string.format("All %d tests passed in %.2fs.", tests_count, os.clock() - start_time))
    end
elseif found == true then
    if tests_count == 1 then
        print("Test failed.")
    else
        print(string.format("%d of %d tests failed in %.2fs.", tests_count_failed, tests_count, os.clock() - start_time))
        print("\nFailure Summary:")
        for msg, count in pairs(failure_summaries) do
            print(string.format("  %dx : %s", count, msg))
        end
    end
end

if use_json then
    print_json_report()
end

if tests_count_failed > 0 then
    os.exit(1)
end
