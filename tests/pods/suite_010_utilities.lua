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
        [s .. "10"] = {
            description = "util.format_line with default target column (44)",
            run = function()
                return util.format_line("short_line", "[OK]")
            end,
            expected = "short_line                                  [OK]"
        },
        [s .. "11"] = {
            description = "util.format_line with dynamic target column",
            run = function()
                return util.format_line("short_line", "[OK]", 20)
            end,
            expected = "short_line          [OK]"
        },
        [s .. "12"] = {
            description = "util.format_line when line is longer than target column",
            run = function()
                return util.format_line("this_is_a_very_long_line", "[OK]", 10)
            end,
            expected = "this_is_a_very_long_line [OK]"
        },
        [s .. "13"] = {
            description = "util.format_line with utf-8 chars",
            run = function()
                -- "überlänge" is 9 visible chars
                return util.format_line("überlänge", "[OK]", 14)
            end,
            expected = "überlänge     [OK]"
        },
        [s .. "14"] = {
            description = "util.parse_size_to_bytes with B",
            run = function()
                return util.parse_size_to_bytes("500 B")
            end,
            expected = 500
        },
        [s .. "15"] = {
            description = "util.parse_size_to_bytes with kB",
            run = function()
                return util.parse_size_to_bytes("1.5 kB")
            end,
            expected = 1500
        },
        [s .. "16"] = {
            description = "util.parse_size_to_bytes with MB",
            run = function()
                return util.parse_size_to_bytes("2 MB")
            end,
            expected = 2000000
        },
        [s .. "17"] = {
            description = "util.parse_size_to_bytes with GB",
            run = function()
                return util.parse_size_to_bytes("1.25 GB")
            end,
            expected = 1250000000
        },
        [s .. "18"] = {
            description = "util.parse_size_to_bytes with no unit",
            run = function()
                return util.parse_size_to_bytes("1024")
            end,
            expected = 1024
        },
        [s .. "19"] = {
            description = "util.format_bytes with B",
            run = function()
                return util.format_bytes(500)
            end,
            expected = "500 B"
        },
        [s .. "20"] = {
            description = "util.format_bytes with kB",
            run = function()
                return util.format_bytes(1500)
            end,
            expected = "1.5 kB"
        },
        [s .. "21"] = {
            description = "util.format_bytes with MB",
            run = function()
                return util.format_bytes(1500000)
            end,
            expected = "1.5 MB"
        },
        [s .. "22"] = {
            description = "util.format_bytes with GB",
            run = function()
                return util.format_bytes(1500000000)
            end,
            expected = "1.5 GB"
        },
    }
}
