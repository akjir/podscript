return {
    -- Tests for system checks like Lua version and Operating System.
    tests = {
        T00901 = {
            description = "Check Lua version (must be >= 5.4).",
            run = function()
                return system.check_lua_version()
            end,
            expected = true,
        },
        T00902 = {
            description = "Check OS compatibility (must be Linux).",
            run = function()
                return system.check_os()
            end,
            expected = true,
        },
    }
}
