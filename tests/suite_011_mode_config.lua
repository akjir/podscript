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
                { 3, "  1: pods:" },
                { 4, "  2:   path: " },
                { 5, "  3: recipes:" },
                { 6, "  4:   groups:" },
                { 7, "  5:     all:" },
                { 8, "  6:   path: ." },
                { 9, "  7: simulate: true" },
            },
        },
    }
}
