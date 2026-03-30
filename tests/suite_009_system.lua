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
        T00903 = {
            description = "Check Podman version (must be >= 5.8.0).",
            run = function()
                return system.check_podman_version()
            end,
            expected = true,
        },
        T00904 = {
            description = "load_lua_file: successful load",
            run = function()
                local path = "/tmp/test_success.lua"
                local file = io.open(path, "w")
                if file then
                    file:write("return { key = 'value' }")
                    file:close()
                end
                local result, error, error_type = system.load_lua_file(path)
                os.remove(path)
                return (result ~= nil and result.key == "value" and error == nil and error_type == nil)
            end,
            expected = true,
        },
        T00905 = {
            description = "load_lua_file: file not found",
            run = function()
                local result, error, error_type = system.load_lua_file("/tmp/non_existent_file.lua")
                return (result == nil and error ~= nil and error_type == "load")
            end,
            expected = true,
        },
        T00906 = {
            description = "load_lua_file: syntax error",
            run = function()
                local path = "/tmp/test_syntax_error.lua"
                local file = io.open(path, "w")
                if file then
                    file:write("return { key = }") -- Syntax error
                    file:close()
                end
                local result, error, error_type = system.load_lua_file(path)
                os.remove(path)
                return (result == nil and error ~= nil and error_type == "load")
            end,
            expected = true,
        },
        T00907 = {
            description = "load_lua_file: execution error",
            run = function()
                local path = "/tmp/test_exec_error.lua"
                local file = io.open(path, "w")
                if file then
                    file:write("error('runtime error')")
                    file:close()
                end
                local result, error, error_type = system.load_lua_file(path)
                os.remove(path)
                -- err should contain "runtime error"
                return (result == nil and error ~= nil and error_type == "execution" and string.find(error, "runtime error") ~= nil)
            end,
            expected = true,
        },
        T00908 = {
            description = "Check if program is run with elevated execution rights (sudo).",
            run = function()
                return system.runs_elevated()
            end,
            expected = false,
        },
    }
}
