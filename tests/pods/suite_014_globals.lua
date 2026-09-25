local s = "014"
return {
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Attempting to assign to an undeclared global triggers compile error.",
            run = function()
                local fn, err = load("global<const> *\nundeclared_test_var = 123")
                return fn == nil and string.find(err or "", "attempt to assign to const variable") ~= nil
            end,
            expected = true
        },
        [s .. "02"] = {
            description = "Attempting to reassign a global<const> variable triggers compile error.",
            run = function()
                local fn, err = load("global<const> *\nglobal my_const<const> = 1\nmy_const = 2")
                return fn == nil and string.find(err or "", "attempt to assign to const variable") ~= nil
            end,
            expected = true
        },
        [s .. "03"] = {
            description = "Modifying fields of global tables (log.debug_enabled) is allowed.",
            run = function()
                local old_val = log.debug_enabled
                log.debug_enabled = not old_val
                local changed_val = log.debug_enabled
                log.debug_enabled = old_val
                return changed_val ~= old_val
            end,
            expected = true
        },
        [s .. "04"] = {
            description = "Standard Lua debug library is intact and not overwritten by a boolean.",
            run = function()
                return type(debug) == "table" and type(debug.traceback) == "function"
            end,
            expected = true
        },
    }
}
