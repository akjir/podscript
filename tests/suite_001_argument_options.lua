return {
    -- Tests for arguments options like --config and --simulate.
    -- config = none,
    tests = {
        T00101 = {
            description = "Complete empty config.",
            config = "config_001_empty",
            action = "create",
            targets = { "target" },
            simulate = false,
            expectations = {
                { 3, "ERROR: No recipes defined in config './tests/configs/config_001_empty.lua'!" },
            },
        },
        T00102 = {
            description = "Force simulate mode through argument and ignore config.",
            config = "config_002_simulate_false",
            action = "create",
            targets = { "target" },
            simulate = true,
            expectations = {
                { 2, "DEBUG: Config './tests/configs/config_002_simulate_false.lua' is used." },
                { 3, "INFO: Simulate mode is active." },
            },
        },
        T00103 = {
            description = "Activate simulate mode through config. Ignore missing argument.",
            config = "config_003_simulate_true",
            action = "create",
            targets = { "target" },
            simulate = false,
            expectations = {
                { 2, "DEBUG: Config './tests/configs/config_003_simulate_true.lua' is used." },
                { 3, "INFO: Simulate mode is active." },
            },
        },
        T00104 = {
            description = "Config not found.",
            config = "config_missing",
            action = "create",
            targets = { "target" },
            expectations = {
                { 3, "ERROR: cannot open ./tests/configs/config_missing.lua: No such file or directory" },
                { 4, "ERROR: Couldn't load configuration './tests/configs/config_missing.lua'!" },
            },
        },
        T00105 = {
            description = "No arguments at all. Print help.",
            expectations = {
                { 3, "Usage: pods [MODE] [OPTIONS] ACTION [TARGETS]" },
            },
        },
        T00106 = {
            description = "Set help flag. Print help.",
            config = "",
            action = "",
            targets = {},
            help = true,
            expectations = {
                { 3, "Usage: pods [MODE] [OPTIONS] ACTION [TARGETS]" },
            },
        },
    }
}
