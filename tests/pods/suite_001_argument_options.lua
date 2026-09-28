local s = "001"
return {
    -- Tests for argument options like --config and --debug.
    -- config = none,
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Complete empty config.",
            config = "config_001_empty",
            parameters = { "create" },
            simulate = false,
            expectations = {
                sequence = {
                    "ERROR: No recipes defined in config './tests/pods/configs/config_001_empty.lua'!"
                }
            },
        },
        [s .. "02"] = {
            description = "Force simulate mode through argument and ignore config.",
            config = "config_002_simulate_false",
            parameters = { "create" },
            simulate = true,
            expectations = {
                sequence = {
                    "DEBUG: Config './tests/pods/configs/config_002_simulate_false.lua' is used.",
                    "INFO: Simulate mode is active."
                }
            },
        },
        [s .. "03"] = {
            description = "Activate simulate mode through config. Ignore missing argument.",
            config = "config_003_simulate_true",
            parameters = { "create" },
            simulate = false,
            expectations = {
                sequence = {
                    "DEBUG: Config './tests/pods/configs/config_003_simulate_true.lua' is used.",
                    "INFO: Simulate mode is active."
                }
            },
        },
        [s .. "04"] = {
            description = "Config not found.",
            config = "config_missing",
            parameters = { "create" },
            expectations = {
                sequence = {
                    "ERROR: cannot open ./tests/pods/configs/config_missing.lua: No such file or directory",
                    "ERROR: Couldn't load configuration './tests/pods/configs/config_missing.lua'!"
                }
            },
        },
        [s .. "05"] = {
            description = "No arguments at all. Print help.",
            expectations = {
                sequence = {
                    "Usage: pods [MODE] [OPTIONS] ACTION [TARGETS]",
                    "logs               show or follow logs for a pod or container"
                }
            },
        },
        [s .. "06"] = {
            description = "Set help flag. Print help.",
            config = "",
            parameters = {},
            help = true,
            expectations = {
                sequence = {
                    "Usage: pods [MODE] [OPTIONS] ACTION [TARGETS]"
                }
            },
        },
        [s .. "07"] = {
            description = "Config extraction: absolute path with extension.",
            config = "",
            parameters = { "--config=/custom/path/to/my_config.lua", "create", "target" },
            expectations = {
                sequence = {
                    "DEBUG: Debug mode is enabled.",
                    "DEBUG: Config '/custom/path/to/my_config.lua.lua' is used.",
                    "ERROR: cannot open /custom/path/to/my_config.lua.lua: No such file or directory",
                    "ERROR: Couldn't load configuration '/custom/path/to/my_config.lua.lua'!"
                }
            },
        },
        [s .. "08"] = {
            description = "Config extraction: relative path without extension.",
            config = "",
            parameters = { "--config=configs/my_config", "create", "target" },
            expectations = {
                sequence = {
                    "DEBUG: Debug mode is enabled.",
                    "DEBUG: Config './configs/my_config.lua' is used.",
                    "ERROR: cannot open ./configs/my_config.lua: No such file or directory",
                    "ERROR: Couldn't load configuration './configs/my_config.lua'!"
                }
            },
        },
        [s .. "09"] = {
            description = "Config extraction: exact name 'config' does not print debug message.",
            config = "",
            parameters = { "--config=/custom/path/to/config.lua", "create", "target" },
            expectations = {
                sequence = {
                    "DEBUG: Debug mode is enabled.",
                    "ERROR: cannot open /custom/path/to/config.lua.lua: No such file or directory",
                    "ERROR: Couldn't load configuration '/custom/path/to/config.lua.lua'!"
                }
            },
        },
    }
}
