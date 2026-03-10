return {
    -- Tests for actions.
    -- config = none,
    tests = {
        T00401 = {
            description = "No action set.",
            config = "config_001_empty",
            targets = { "target" },
            expectations = {
                { 1, "ERROR: Unknown action 'target'." },
            },
        },
    },
}
