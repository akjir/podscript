local s = "009"
return {
    -- Tests for system checks like Lua version and Operating System.
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Check Lua version (must be >= 5.5).",
            run = function()
                return system.check_lua_version()
            end,
            expected = true,
        },
        [s .. "02"] = {
            description = "Check OS compatibility (must be Linux).",
            run = function()
                return system.check_os()
            end,
            expected = true,
        },
        [s .. "03"] = {
            description = "Check Podman version (must be >= 5.8.0).",
            run = function()
                return system.check_podman_version()
            end,
            expected = true,
        },
        [s .. "04"] = {
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
        [s .. "05"] = {
            description = "load_lua_file: file not found",
            run = function()
                local result, error, error_type = system.load_lua_file("/tmp/non_existent_file.lua")
                return (result == nil and error ~= nil and error_type == "load")
            end,
            expected = true,
        },
        [s .. "06"] = {
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
        [s .. "07"] = {
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
        [s .. "08"] = {
            description = "Check if program is run with elevated execution rights (sudo).",
            run = function()
                return system.runs_elevated()
            end,
            expected = false,
        },
        [s .. "09"] = {
            description = "system.file_exists returns true for existing file and false for non-existent.",
            run = function()
                local exists_true = system.file_exists("recipe.lua")
                local exists_false = system.file_exists("/tmp/non_existent_file_podscript.lua")
                return exists_true == true and exists_false == false
            end,
            expected = true,
        },
        [s .. "10"] = {
            description = "system.directory_exists returns true for existing directory and false for non-existent.",
            run = function()
                local exists_true = system.directory_exists("/tmp")
                local exists_false = system.directory_exists("/tmp/non_existent_directory_podscript")
                return exists_true == true and exists_false == false
            end,
            expected = true,
        },
        [s .. "11"] = {
            description = "system.list_directory returns list of files.",
            run = function()
                -- Create a temp dir and some files
                local test_dir = "/tmp/test_podscript_list_dir"
                os.execute("mkdir -p " .. test_dir)
                os.execute("touch " .. test_dir .. "/a.lua " .. test_dir .. "/b.txt " .. test_dir .. "/c.lua")

                local files_all = system.list_directory(test_dir)
                local files_lua = system.list_directory(test_dir, "%.lua$")
                local files_none = system.list_directory(test_dir, "%.nonexistent$")

                os.execute("rm -rf " .. test_dir)

                return files_all ~= nil and #files_all == 3
                   and files_lua ~= nil and #files_lua == 2
                   and files_none ~= nil and #files_none == 0
            end,
            expected = true,
        },
        [s .. "12"] = {
            description = "system.write_file writes content to file correctly.",
            run = function()
                local test_path = "/tmp/test_system_write_file.txt"
                local content = "hello world\n"
                local write_success = system.write_file(test_path, content)
                local file = io.open(test_path, "r")
                local read_content = file and file:read("*a")
                if file then file:close() end
                os.remove(test_path)
                return write_success == true and read_content == content
            end,
            expected = true,
        },
        [s .. "13"] = {
            description = "system.exec works with interactive=true.",
            run = function()
                -- Execute a basic command interactively. It should succeed.
                local success, _, exit_code = system.exec("echo 'test' > /dev/null", { interactive = true, silent = true })
                return success == true and exit_code == 0
            end,
            expected = true,
        },
        [s .. "14"] = {
            description = "system.container_exists returns true when container is running.",
            run = function()
                local old_exec_capture = system.exec_capture
                system.exec_capture = function(cmd)
                    if string.match(cmd, "podman container inspect") then
                        return {"running"}
                    end
                    return {}
                end
                local exists = system.container_exists("my_container")
                system.exec_capture = old_exec_capture
                return exists
            end,
            expected = true,
        },
        [s .. "15"] = {
            description = "system.container_exists returns false when container is not running.",
            run = function()
                local old_exec_capture = system.exec_capture
                system.exec_capture = function(cmd)
                    if string.match(cmd, "podman container inspect") then
                        return {"exited"}
                    end
                    return {}
                end
                local exists = system.container_exists("my_container")
                system.exec_capture = old_exec_capture
                return exists
            end,
            expected = false,
        },
        [s .. "16"] = {
            description = "system.exec_capture captures output correctly and returns success=true on zero exit.",
            run = function()
                local lines, success = system.exec_capture("echo 'hello'; echo 'world'")
                return lines ~= nil and #lines == 2 and lines[1] == "hello" and lines[2] == "world" and success == true
            end,
            expected = true,
        },
        [s .. "17"] = {
            description = "system.exec_capture returns success=false when command fails and suppresses STDERR.",
            run = function()
                -- Trying to cat a nonexistent file will output to stderr, which should be suppressed
                local lines, success = system.exec_capture("cat /non/existent/path/for/test/123")
                return lines ~= nil and #lines == 0 and success == false
            end,
            expected = true,
        },
        [s .. "18"] = {
            description = "system.exec does not append semicolon to background commands.",
            run = function()
                -- Test that a command ending with & does not fail with syntax error
                local success, _, exit_code = system.exec("sleep 0.01 &", { interactive = false, silent = true })
                return success == true and exit_code == 0
            end,
            expected = true,
        },
    }
}
