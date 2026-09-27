local s = "011"
return {
    -- Tests for config mode.
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Print config help.",
            parameters = { "config", "help" },
            expectations = {
                sequence = {
                    "Usage: pods config [OPTIONS] ACTION"
                }
            },
        },
        [s .. "02"] = {
            description = "Print current config.",
            config = "config_003_simulate_true",
            parameters = { "config", "print" },
            expectations = {
                sequence = {
                    "  1: return {",
                    "  2:     simulate = true,",
                    "  3:     recipes = {",
                    "  4:         groups = {",
                    "  5:             all = {}",
                    "  6:         },",
                    "  7:     },",
                    "  8: }"
                }
            },
        },
        [s .. "03"] = {
            description = "Edit config with no editor configured.",
            config = "config_011_no_editor",
            parameters = { "config", "edit" },
            expectations = {
                sequence = {
                    "ERROR: No editor configured."
                }
            },
        },
        [s .. "04"] = {
            description = "Edit config with invalid editor.",
            config = "config_012_invalid_editor",
            parameters = { "config", "edit" },
            expectations = {
                sequence = {
                    "DEBUG: Execute: editor ./tests/pods/configs/config_012_invalid_editor.lua;",
                    "ERROR: Command exited with code '127'!"
                }
            },
        },
        [s .. "05"] = {
            description = "Print current config (no action).",
            config = "config_003_simulate_true",
            parameters = { "config" },
            expectations = {
                sequence = {
                    "  1: return {",
                    "  2:     simulate = true,",
                    "  3:     recipes = {",
                    "  4:         groups = {",
                    "  5:             all = {}",
                    "  6:         },",
                    "  7:     },",
                    "  8: }"
                }
            },
        },
    }
}
