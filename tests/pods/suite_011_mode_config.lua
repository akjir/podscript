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
            description = "Show current config.",
            config = "config_003_simulate_true",
            parameters = { "config", "show" },
            expectations = {
                sequence = {
                    "Configuration:",
                    "Settings:",
                    "  Simulate:     true",
                    "Directories:",
                    "Groups:",
                    "  • all"
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
            description = "Show current config (no action).",
            config = "config_003_simulate_true",
            parameters = { "config" },
            expectations = {
                sequence = {
                    "Configuration:",
                    "Settings:",
                    "  Simulate:     true",
                    "Directories:",
                    "Groups:",
                    "  • all"
                }
            }
        },
        [s .. "06"] = {
            description = "Show config with validation warnings.",
            config = "config_013_validation",
            parameters = { "config", "show" },
            expectations = {
                sequence = {
                    "[NOT FOUND]",
                    "[OK",
                    "  • all",
                    "    └── missing_recipe                      [NOT FOUND]",
                    "  • database",
                    "    └── recipe_001_empty                    [OK]",
                    "  • stack",
                    "    ├── @database",
                    "    │   └── recipe_001_empty                [OK]",
                    "    └── @web",
                    "        └── frontend                        [NOT FOUND]",
                    "  • web",
                    "    └── frontend                            [NOT FOUND]",
                    "Validation Summary:",
                    "- Recipe files for 'frontend' and 'missing_recipe' not found!",
                    "- Potentially unreferenced recipe files 'recipe_002_no_pod.lua'"
                }
            }
        }
    }
}
