local s = "018"
return {
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Test if compiled pods.lua runs 'status' successfully in release mode.",
            run = function()
                local handle = io.popen("lua pods.lua status 2>&1")
                if not handle then return -1 end
                local result = handle:read("*a")
                local success, reason, exit_code = handle:close()
                if not success then
                    print("Output:\n" .. result)
                end
                return exit_code or 0
            end,
            expected = 0
        },
        [s .. "02"] = {
            description = "Test if compiled pods.lua runs 'create' in simulate mode successfully.",
            run = function()
                local handle = io.popen("lua pods.lua --config=tests/pods/configs/config_008_containers create --simulate 2>&1")
                if not handle then return -1 end
                local result = handle:read("*a")
                local success, reason, exit_code = handle:close()
                if not success then
                    print("Output:\n" .. result)
                end
                return exit_code or 0
            end,
            expected = 0
        }
    }
}
