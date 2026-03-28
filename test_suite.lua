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

-- ------------------------------------------------------------------------- --
--   PODSCRIPT TEST
-- ------------------------------------------------------------------------- --

require "pods"
require "tests/test_helpers"

local output_stack = {}
local single_test_name = ""
local tests_count = 0
local tests_count_failed = 0

--- set mode and complete print
if #arg ~= 0 then
    for i = 1, #arg do
        local argument = arg[i]
        if single_test_name == "" then
            single_test_name = argument
        end
    end
end

---Print function
---@param str string
local function print_to_stack(str)
    output_stack[#output_stack + 1] = str
end

-- global function for printing in pods.lua
print_internal = print_to_stack

-- set debug flag in pods.lua
debug = true

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

-- ------------------------------------------------------------------------- --
--      Execute Tests
-- ------------------------------------------------------------------------- --

local function execute_normal_test(default_config_name, test_code, test_table, print_stack)
    local config_name = table.get_or_default(test_table, "config", "")
    local arguments = {}

    if config_name == "" then
        if default_config_name ~= "" then
            table.insert(arguments, "--config")
            table.insert(arguments, "tests/configs/" .. default_config_name)
        end
    else
        table.insert(arguments, "--config")
        table.insert(arguments, "tests/configs/" .. config_name)
    end
    if test_table.help then
        table.insert(arguments, "--help")
    end
    if test_table.simulate then
        table.insert(arguments, "--simulate")
    end
    table.insert(arguments, test_table.action)
    table.append(arguments, test_table.targets)

    -- execute pods.lua with arguments
    main(arguments)

    local expectations = test_table.expectations
    for _, expectation in pairs(expectations) do
        local line = expectation[1]
        local expected_result = expectation[2]
        local result = output_stack[line]

        if result ~= expected_result then
            local description = test_table.description
            print("## Test '" .. test_code .. "' failed at line " .. line .. ".")
            if not string.is_nil_or_empty(description) then
                print(" Description: " .. test_table.description)
            end
            print(" Call: lua pods.lua " .. table.concat(arguments, " "))
            print()
            print("  Result:   '" .. tostring(result) .. "'")
            print("  Expected: '" .. expected_result .. "'")
            if print_stack then print_full_stack(output_stack) else print() end
            -- clear output_stack
            output_stack = {}
            -- test failed, return false
            return false
        end
    end
    -- clear output_stack
    output_stack = {}
    -- test successfull, retrun true
    return true
end

---Executes a code test. Test has to have a run() function and an expected value.
---@param test_code string
---@param test_table table
local function execute_code_test(test_code, test_table, print_stack)
    local result = test_table.run()
    if result ~= test_table.expected then
        local description = test_table.description
        print("## Test '" .. test_code .. "' failed.")
        if not string.is_nil_or_empty(description) then
            print(" Description: " .. test_table.description)
        end
        print()
        print("  Result:   '" .. tostring(result) .. "'")
        print("  Expected: '" .. tostring(test_table.expected) .. "'")
        if print_stack then print_full_stack(output_stack) else print() end
        return false
    end
    -- clear output_stack
    output_stack = {}
    -- test successfull, retrun true
    return true
end

local function execute_test(default_config_name, test_code, test_table, print_stack)
    if test_table.run ~= nil then
        if not execute_code_test(test_code, test_table, print_stack) then
            tests_count_failed = tests_count_failed + 1
        end
    else
        if not execute_normal_test(default_config_name, test_code, test_table, print_stack) then
            tests_count_failed = tests_count_failed + 1
        end
    end
end

local function execute_test_suite(test_suite)
    local tests = test_suite.tests
    for test_code, test_table in pairs(tests) do
        local default_config_name = table.get_or_default(test_suite, "config", "")
        tests_count = tests_count + 1
        execute_test(default_config_name, test_code, test_table, false)
    end
end

-- ------------------------------------------------------------------------- --
--      Test Suits
-- ------------------------------------------------------------------------- --

local test_suites = {}

local function add_suite(name)
    local suite = require("tests/" .. name)
    suite.name = name
    table.insert(test_suites, suite)
end

add_suite("suite_001_argument_options")
add_suite("suite_002_helpers_string")
add_suite("suite_003_helpers_table")
add_suite("suite_004_actions")
add_suite("suite_005_targets")
add_suite("suite_006_recipes")
add_suite("suite_007_pods")
add_suite("suite_008_containers")

-- ------------------------------------------------------------------------- --
--      Main
-- ------------------------------------------------------------------------- --

local found = false -- define here to prevent "Test failed." if no test was found
print()
if single_test_name == "" then
    found = true
    for _, test_suite in pairs(test_suites) do
        execute_test_suite(test_suite)
    end
else
    local run_count = 0
    for a, test_suite in pairs(test_suites) do
        -- Check if it matches a suite name
        if test_suite.name == single_test_name or test_suite.name .. ".lua" == single_test_name then
            found = true
            for test_code, test_table in pairs(test_suite.tests) do
                local default_config_name = table.get_or_default(test_suite, "config", "")
                execute_test(default_config_name, test_code, test_table, true)
                run_count = run_count + 1
            end
        else
            -- Check individual tests by code
            local default_config_name = table.get_or_default(test_suite, "config", "")
            for test_code, test_table in pairs(test_suite.tests) do
                if test_code == single_test_name then
                    found = true
                    execute_test(default_config_name, test_code, test_table, true)
                    run_count = run_count + 1
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
        print("All " .. tests_count .. " tests passed.")
    end
elseif found == true then
    if tests_count == 1 then
        print("Test failed.")
    else
        print(tests_count_failed .. " of " .. tests_count .. " tests failed.")
    end
end
