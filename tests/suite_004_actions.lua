local s = "004"
return {
    -- Tests for actions.
    -- config = none,
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "No action set.",
            config = "config_005_recipes",
            targets = { "target" },
            expectations = {
                { 3, "ERROR: Unknown action 'target'." },
            },
        },
    },
}
