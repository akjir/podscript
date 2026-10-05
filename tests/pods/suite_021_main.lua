local s = "021"
return {
    suite = s,
    description = "Main arguments and flag parsing",
    tests = {
        [s .. "01"] = {
            description = "Parse --simulate correctly.",
            config = "config_002_simulate_false",
            parameters = { "create", "--simulate" },
            expectations = {
                sequence = {
                    "INFO: Simulate mode is active."
                }
            },
        },
        [s .. "02"] = {
            description = "Argument stripping: --simulate doesn't affect mode.",
            config = "config_002_simulate_false",
            parameters = { "--simulate", "create" },
            expectations = {
                sequence = {
                    "INFO: Simulate mode is active."
                }
            },
        },
        [s .. "03"] = {
            description = "Config precedence: config overrides default, but flag overrides config? Actually, flag sets it to true.",
            config = "config_002_simulate_false",
            parameters = { "create", "--simulate" },
            expectations = {
                sequence = {
                    "INFO: Simulate mode is active."
                }
            },
        },
        [s .. "04"] = {
            description = "Global enforcement: config.simulate = true forces dry-runs.",
            config = "config_003_simulate_true",
            parameters = { "create" },
            expectations = {
                sequence = {
                    "INFO: Simulate mode is active."
                }
            },
        },
    }
}
