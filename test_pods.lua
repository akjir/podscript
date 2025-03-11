--[[

PodScript
Copyright (C) 2025  Stefan Stark

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
local command_stack = {}

---Print function get 
---@param str string
local function prt(str)
    command_stack[#command_stack + 1] = str
end

print_hook = prt

-- ------------------------------------------------------------------------- --
--      Execute Tests
-- ------------------------------------------------------------------------- --

local function execute_test(config_name, test_name, test_table)
    local arguments = {}
    if test_table.plain ~= nil then
        arguments = test_table.plain
    else
        arguments = {
            "--config",
            "test_podscript_configs/" .. config_name,
            test_table.action,
            test_table.target,
        }
    end

    -- execute pods.lua with arguments
    main(arguments)

    local expectations = test_table.expectations
    for _, expectation in pairs(expectations) do
        local line = expectation[1]
        local expected_result = expectation[2]
        local result = command_stack[line]

        if result ~= expected_result then
            local description = test_table.description
            if description == nil then description = "" end
            if result == nil then result = "nil" end
            print("## Test '" .. test_name .. "' failed at line " .. line .. ".")
            if description ~= "" then print(" Description: " .. test_table.description) end
            print(" Arguments: " .. table.concat(arguments, " "))
            print()
            print("  Result:   '" .. result .. "'")
            print("  Expected: '" .. expected_result .. "'")
            print()
            -- clear command_stack
            command_stack = {}
            -- test failed, return false
            return false
        end
    end

    -- clear command_stack
    command_stack = {}
    -- test successfull, retrun true
    return true
end

local function execute_test_group(group)
    local tests = group.tests
    for test_name, test_table in pairs(tests) do
        tests_count = tests_count + 1
        if not execute_test(group.config_name, test_name, test_table) then
            tests_count_failed = tests_count_failed + 1
        end
    end
end

-- ------------------------------------------------------------------------- --
--      Tests
-- ------------------------------------------------------------------------- --

execute_test_group(require "tests/test_psc_001")

-- ------------------------------------------------------------------------- --
--      Summary
-- ------------------------------------------------------------------------- --

if tests_count_failed == 0 then
    print("All " .. tests_count .." tests passed.")
else
    print(tests_count_failed .. " of " .. tests_count .. " tests failed.")
end