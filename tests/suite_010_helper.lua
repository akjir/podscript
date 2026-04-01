local s = "010"
return {
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Normalize name: trim, spaces to underscores, lowercase.",
            dev_only = true,
            run = function()
                return normalize_name("  My  Name  ")
            end,
            expected = "my_name"
        },
        [s .. "02"] = {
            description = "Build full path: relative path, name, extension.",
            dev_only = true,
            run = function()
                return build_full_path("test/path", "file", ".lua")
            end,
            expected = "./test/path/file.lua"
        },
        [s .. "03"] = {
            description = "Build full path: absolute path.",
            dev_only = true,
            run = function()
                return build_full_path("/test/path", "file", ".lua")
            end,
            expected = "/test/path/file.lua"
        },
        [s .. "04"] = {
            description = "Build full path: path ends with slash.",
            dev_only = true,
            run = function()
                return build_full_path("./test/path/", "file", ".lua")
            end,
            expected = "./test/path/file.lua"
        },
        [s .. "05"] = {
            description = "Split argument: key=value.",
            dev_only = true,
            run = function()
                local k, v = split_argument("--config=my_config")
                return k .. "=" .. v
            end,
            expected = "config=my_config"
        },
        [s .. "06"] = {
            description = "Split argument: flag (no value).",
            dev_only = true,
            run = function()
                local k, v = split_argument("--simulate")
                return k .. "=" .. tostring(v)
            end,
            expected = "simulate=true"
        },
        [s .. "07"] = {
            description = "Parse action and targets: multiple targets.",
            dev_only = true,
            run = function()
                local registry = { parameters = { "create", "recipe1", "recipe2" } }
                local action, targets = parse_action_and_targets_parameters(registry)
                return action .. ":" .. table.concat(targets, ",")
            end,
            expected = "create:recipe1,recipe2"
        },
        [s .. "08"] = {
            description = "Parse action and targets: only action, no targets.",
            dev_only = true,
            run = function()
                local registry = { parameters = { "list" } }
                local action, targets = parse_action_and_targets_parameters(registry)
                return action .. ":" .. table.concat(targets, ",")
            end,
            expected = "list:"
        },
    }
}
