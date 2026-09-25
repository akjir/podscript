local s = "015"
return {
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Named vararg table captures argument count and elements correctly.",
            run = function()
                local function test_fn(... args)
                    return args.n, args[1], args[2], args[3]
                end
                local n, a1, a2, a3 = test_fn("hello", 123, true)
                return n == 3 and a1 == "hello" and a2 == 123 and a3 == true
            end,
            expected = true
        },
        [s .. "02"] = {
            description = "Named vararg table captures nil elements and preserves total count in args.n.",
            run = function()
                local function test_fn(... args)
                    return args.n, args[1], args[2], args[3]
                end
                local n, a1, a2, a3 = test_fn("first", nil, "third")
                return n == 3 and a1 == "first" and a2 == nil and a3 == "third"
            end,
            expected = true
        },
        [s .. "03"] = {
            description = "Reassigning the named vararg parameter triggers compile error (const variable).",
            run = function()
                local fn, err = load("local function f(... args) args = {} end")
                return fn == nil and string.find(err or "", "attempt to assign to const variable") ~= nil
            end,
            expected = true
        },
        [s .. "04"] = {
            description = "log.format_args formats zero, single, and multiple arguments correctly.",
            run = function()
                local empty = log.format_args()
                local single = log.format_args("single")
                local multi = log.format_args("a", 1, false, "z")
                return empty == "" and single == "single" and multi == "a 1 false z"
            end,
            expected = true
        },
        [s .. "05"] = {
            description = "log.info with multiple arguments formats space-separated output.",
            run = function()
                local captured = nil
                local old_print = log.print
                log.print = function(msg) captured = msg end
                log.info("Container", "web", "port", 8080)
                log.print = old_print
                return captured
            end,
            expected = "INFO: Container web port 8080"
        },
        [s .. "06"] = {
            description = "log.debug respects log.debug_enabled flag with multiple arguments.",
            run = function()
                local captured = nil
                local old_print = log.print
                local old_debug = log.debug_enabled
                log.print = function(msg) captured = msg end

                log.debug_enabled = false
                log.debug("Should", "not", "appear")
                local test1 = captured == nil

                log.debug_enabled = true
                log.debug("Should", "appear", 42)
                local test2 = captured == "DEBUG: Should appear 42"

                log.print = old_print
                log.debug_enabled = old_debug
                return test1 and test2
            end,
            expected = true
        },
        [s .. "07"] = {
            description = "log.warning and log.error with multiple arguments.",
            run = function()
                local warnings, errors = {}, {}
                local old_print = log.print
                log.print = function(msg)
                    if string.begins_with(msg, "WARNING: ") then
                        warnings[#warnings + 1] = msg
                    elseif string.begins_with(msg, "ERROR: ") then
                        errors[#errors + 1] = msg
                    end
                end
                log.warning("Disk", 95, "%")
                log.error("Failed", 404, "Not Found")
                log.print = old_print
                return warnings[1] == "WARNING: Disk 95 %" and errors[1] == "ERROR: Failed 404 Not Found"
            end,
            expected = true
        },
        [s .. "08"] = {
            description = "table.append with multiple sequential tables.",
            run = function()
                local target = { 1, 2 }
                table.append(target, { 3, 4 }, { 5 }, { 6, 7 })
                return table.to_string(target)
            end,
            expected = table.to_string({ 1, 2, 3, 4, 5, 6, 7 })
        },
        [s .. "09"] = {
            description = "table.append with nil sources in between.",
            run = function()
                local target = { "a" }
                table.append(target, nil, { "b" }, nil, { "c" })
                return table.to_string(target)
            end,
            expected = table.to_string({ "a", "b", "c" })
        },
        [s .. "10"] = {
            description = "table.merge with multiple tables and overwrite precedence.",
            run = function()
                local target = { a = 1, b = 2 }
                table.merge(target, { b = 20, c = 3 }, { c = 30, d = 4 })
                return table.to_string(target)
            end,
            expected = table.to_string({ a = 1, b = 20, c = 30, d = 4 })
        },
        [s .. "11"] = {
            description = "table.merge with nil sources.",
            run = function()
                local target = { x = 10 }
                table.merge(target, nil, { y = 20 }, nil)
                return table.to_string(target)
            end,
            expected = table.to_string({ x = 10, y = 20 })
        },
    }
}
