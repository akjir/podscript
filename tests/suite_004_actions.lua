return {
    -- Tests for actions.
    -- config = none,
    tests = {
        T00401 = {
            description = "No action set.",
            config = "config_005_recipes",
            targets = { "target" },
            expectations = {
                { 3, "ERROR: Unknown action 'target'." },
            },
        },
    },
}
