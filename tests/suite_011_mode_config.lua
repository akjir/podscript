local s = "011"
return {
    -- Tests for config mode.
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Print config help.",
            parameters = { "config", "help" },
            expectations = {
                { 3, "Usage: pods config [OPTIONS] ACTION [TARGETS]" },
            },
        },
        [s .. "02"] = {
            description = "Print current config.",
            config = "config_003_simulate_true",
            parameters = { "config", "print" },
            expectations = {
                { 3, "simulate: true" },
                { 4, "pods:" },
                { 5, "  path: " },
                { 6, "recipes:" },
                { 7, "  path: ./" },
                { 8, "  groups:" },
                { 9, "    - all" },
            },
        },
    }
}
