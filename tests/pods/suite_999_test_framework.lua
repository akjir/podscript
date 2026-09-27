local s = "999"

local suite = {
    suite = s,
    description = "Test Framework Resiliency",
    tests = {}
}

suite.tests[s .. "01"] = {
    description = "Test execute_unit_test success",
    run = function()
        log.print("DEBUG: some log")
        log.print("INFO: some other log")
        return true
    end,
    expected = true,
    expectations = {
                sequence = {
                    "DEBUG: some log",
                    "INFO: some other log"
            },
        contains = {
            "some log"
        },
        not_contains = {
            "ERROR: this should not exist"
        },
        matches = {
            "INFO:.*log"
        },
        count = {
            ["some log"] = 1,
            ["other log"] = 1
        }
    }
}

suite.tests[s .. "02"] = {
    description = "Test log provenance skip (test_utilities)",
    run = function()
        -- In test framework log.print from suite should have suite_999_test_framework.lua provenance
        log.print("Hello from test framework")
        return 42
    end,
    expected = 42,
    expectations = {
        matches = {
            "%[suite_999_test_framework%.lua:%d+%] Hello from test framework"
        }
    }
}

suite.tests[s .. "03"] = {
    description = "Test evaluate_assertions catches missing sequence",
    run = function()
        local errors = {}
        _G.__TEST_FRAMEWORK.evaluate_assertions({
            sequence = { "first", "third" }
        }, errors, { "INFO: first", "INFO: second" })
        return errors[1]
    end,
    expected = "Missing in sequence: 'third'"
}

suite.tests[s .. "04"] = {
    description = "Test evaluate_assertions catches count mismatch",
    run = function()
        local errors = {}
        _G.__TEST_FRAMEWORK.evaluate_assertions({
            count = { ["INFO: apple"] = 2 }
        }, errors, { "INFO: apple", "INFO: banana" })
        return errors[1]
    end,
    expected = "Count mismatch for 'INFO: apple': expected 2, found 1"
}

suite.tests[s .. "05"] = {
    description = "Test evaluate_assertions catches unwanted log (not_contains)",
    run = function()
        local errors = {}
        _G.__TEST_FRAMEWORK.evaluate_assertions({
            not_contains = { "ERROR:" }
        }, errors, { "INFO: good", "ERROR: bad" })
        return errors[1]
    end,
    expected = "Found 'not_contains': ERROR:"
}

suite.tests[s .. "06"] = {
    description = "Test evaluate_assertions catches missing contains",
    run = function()
        local errors = {}
        _G.__TEST_FRAMEWORK.evaluate_assertions({
            contains = { "missing log" }
        }, errors, { "INFO: good log", "INFO: another log" })
        return errors[1]
    end,
    expected = "Missing 'contains': missing log"
}

suite.tests[s .. "07"] = {
    description = "Test evaluate_assertions catches missing matches",
    run = function()
        local errors = {}
        _G.__TEST_FRAMEWORK.evaluate_assertions({
            matches = { "^ERROR:.*" }
        }, errors, { "INFO: good log" })
        return errors[1]
    end,
    expected = "Missing 'matches': ^ERROR:.*"
}

suite.tests[s .. "08"] = {
    description = "Test evaluate_assertions catches out-of-order sequence",
    run = function()
        local errors = {}
        _G.__TEST_FRAMEWORK.evaluate_assertions({
            sequence = { "INFO: second", "INFO: first" }
        }, errors, { "INFO: first", "INFO: second" })
        return errors[1]
    end,
    expected = "Missing in sequence: 'INFO: first'"
}

suite.tests[s .. "09"] = {
    description = "Test evaluate_assertions collects multiple errors",
    run = function()
        local errors = {}
        _G.__TEST_FRAMEWORK.evaluate_assertions({
            contains = { "missing" },
            not_contains = { "ERROR" }
        }, errors, { "INFO: good", "ERROR: bad" })
        return #errors
    end,
    expected = 2
}

return suite
