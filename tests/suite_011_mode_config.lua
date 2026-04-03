local s = "011"
return {
    -- Tests for config mode.
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Print config help.",
            parameters = { "config", "help" },
            expectations = {
                { 4, "Usage: pods config [OPTIONS] ACTION" },
            },
        },
        [s .. "02"] = {
            description = "Print current config.",
            config = "config_003_simulate_true",
            parameters = { "config", "print" },
            expectations = {
                { 4,  "  1: return {" },
                { 5,  "  2:     simulate = true," },
                { 6,  "  3:     recipes = {" },
                { 7,  "  4:         groups = {" },
                { 8,  "  5:             all = {}" },
                { 9,  "  6:         }," },
                { 10, "  7:     }," },
                { 11, "  8: }" },
            },
        },
        [s .. "03"] = {
            description = "Edit config with no editor configured.",
            config = "config_011_no_editor",
            parameters = { "config", "edit" },
            expectations = {
                { 4, "ERROR: No editor configured." },
            },
        },
        [s .. "04"] = {
            description = "Edit config with invalid editor.",
            config = "config_012_invalid_editor",
            parameters = { "config", "edit" },
            expectations = {
                { 4, "DEBUG: Execute: editor ./tests/configs/config_012_invalid_editor.lua;" },
                { 5, "ERROR: Command exited with code '127'!" },
            },
        },
    }
}
