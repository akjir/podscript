local s = "011"
return {
    -- Tests for config mode actions.
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Print config help.",
            action = "config",
            targets = { "help" },
            expectations = {
                { 3, "Usage: pods config [OPTIONS] ACTION [TARGETS]" },
            },
        },
    }
}
