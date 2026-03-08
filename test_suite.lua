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

local tests_count = 0
local tests_count_failed = 0
local output_stack = {}

---Print function
---@param str string
local function print_to_stack(str)
    output_stack[#output_stack + 1] = str
end

-- global function for printing in pods.lua
print_internal = print_to_stack

-- ------------------------------------------------------------------------- --
--      Execute Tests
-- ------------------------------------------------------------------------- --

local function execute_test(default_config_name, test_name, test_table)
    -- replace default config if the test have a specific config set
    local config_name = table.get_or_default(test_table, "config", default_config_name)
    if config_name ~= "" then
        config_name = "tests/configs/" .. config_name
    end

    local arguments = {
        "--config",
        config_name,
    }
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
            if description == nil then description = "" end
            if result == nil then result = "nil" end
            print("## Test '" .. test_name .. "' failed at line " .. line .. ".")
            if description ~= "" then print(" Description: " .. test_table.description) end
            print(" Call: lua pods.lua " .. table.concat(arguments, " "))
            print()
            print("  Result:   '" .. result .. "'")
            print("  Expected: '" .. expected_result .. "'")
            print()
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

local function execute_test_group(test_group)
    local tests = test_group.tests
    for test_code, test_table in pairs(tests) do
        tests_count = tests_count + 1
        if not execute_test(test_group.default_config, test_code, test_table) then
            tests_count_failed = tests_count_failed + 1
        end
    end
end

-- ------------------------------------------------------------------------- --
--      Tests
-- ------------------------------------------------------------------------- --

execute_test_group(require "tests/suite_001_main")

-- ------------------------------------------------------------------------- --
--      Summary
-- ------------------------------------------------------------------------- --

if tests_count_failed == 0 then
    print("All " .. tests_count .. " tests passed.")
else
    print(tests_count_failed .. " of " .. tests_count .. " tests failed.")
end
