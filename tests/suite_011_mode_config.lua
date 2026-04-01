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
    }
}
