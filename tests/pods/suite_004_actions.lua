local s = "004"
return {
    -- Tests for actions.
    -- config = none,
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "No action set.",
            config = "config_005_recipes",
            parameters = { "target" },
            expectations = {
                { 4, "ERROR: Unknown action 'target'." },
            },
        },
    },
}
