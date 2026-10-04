local s = "010"
return {
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Normalize name: trim, spaces to underscores, lowercase.",
            dev_only = true,
            run = function()
                return util.normalize_name("  My  Name  ")
            end,
            expected = "my_name"
        },
        [s .. "02"] = {
            description = "Build full path: relative path, name, extension.",
            dev_only = true,
            run = function()
                return util.build_full_path("test/path", "file", ".lua")
            end,
            expected = "./test/path/file.lua"
        },
        [s .. "03"] = {
            description = "Build full path: absolute path.",
            dev_only = true,
            run = function()
                return util.build_full_path("/test/path", "file", ".lua")
            end,
            expected = "/test/path/file.lua"
        },
        [s .. "04"] = {
            description = "Build full path: path ends with slash.",
            dev_only = true,
            run = function()
                return util.build_full_path("./test/path/", "file", ".lua")
            end,
            expected = "./test/path/file.lua"
        },
        [s .. "05"] = {
            description = "Split argument: key=value.",
            dev_only = true,
            run = function()
                local k, v = util.split_argument("--config=my_config")
                return k .. "=" .. v
            end,
            expected = "config=my_config"
        },
        [s .. "06"] = {
            description = "Split argument: flag (no value).",
            dev_only = true,
            run = function()
                local k, v = util.split_argument("--dry-run")
                return k .. "=" .. tostring(v)
            end,
            expected = "dry-run=true"
        },

        [s .. "09"] = {
            description = "Get version string in development mode.",
            dev_only = true,
            run = function()
                local ver = rawget(_G, "VERSION") or ""
                return get_version_string() == ("v" .. ver .. "+dev")
            end,
            expected = true
        },
    }
}
