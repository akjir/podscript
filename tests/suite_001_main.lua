return {
    -- default_config = "config_001",
    tests = {
        T00101 = {
            description = "Empty config.",
            config = "config_001_empty",
            action = "create",
            targets = {"target"},
            simulate = false,
            expectations = {
                {1, "INFO: Simulate mode is active."},
                {2, "INFO: Config 'tests/configs/config_001_empty' is used."},
                {3, "ERROR: No recipes defined in config!"},
            },
        },
    }
}