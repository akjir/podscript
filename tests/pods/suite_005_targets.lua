local s = "005"
return {
    -- Tests for targets.
    config = "config_004_targets",
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "No targets given as arguments.",
            parameters = { "create" },
            expectations = {
                sequence = {
                    "ERROR: No targets set."
                }
            },
        },
        [s .. "02"] = {
            description = "Unknow target given.",
            parameters = { "create", "invalid" },
            expectations = {
                sequence = {
                    "ERROR: Recipe 'invalid' not found in config."
                }
            },
        },
        [s .. "03"] = {
            description = "Unknow group given.",
            parameters = { "create", "@invalid" },
            expectations = {
                sequence = {
                    "ERROR: Unknown recipe group '@invalid'."
                }
            },
        },
        [s .. "04"] = {
            description = "One target given.",
            parameters = { "create", "target" },
            expectations = {
                sequence = {
                    "DEBUG: Targets   - target",
                    "DEBUG: Untangled - target"
                }
            },
        },
        [s .. "05"] = {
            description = "One group given.",
            parameters = { "create", "@stack" },
            expectations = {
                sequence = {
                    "DEBUG: Targets   - @stack",
                    "DEBUG: Untangled - push pop"
                }
            },
        },
        [s .. "06"] = {
            description = "Three targets, but one is invalid.",
            parameters = { "create", "push", "invalid", "pop" },
            expectations = {
                sequence = {
                    "DEBUG: Targets   - push invalid pop",
                    "ERROR: Recipe 'invalid' not found in config."
                }
            },
        },
        [s .. "07"] = {
            description = "One target, one group.",
            parameters = { "create", "target", "@stack" },
            expectations = {
                sequence = {
                    "DEBUG: Targets   - target @stack",
                    "DEBUG: Untangled - target push pop"
                }
            },
        },
        [s .. "08"] = {
            description = "Same target twice.",
            parameters = { "create", "target", "target" },
            expectations = {
                sequence = {
                    "DEBUG: Targets   - target target",
                    "DEBUG: Untangled - target"
                }
            },
        },
        [s .. "09"] = {
            description = "Same target twice, one group.",
            parameters = { "create", "target", "@stack", "target" },
            expectations = {
                sequence = {
                    "DEBUG: Targets   - target @stack target",
                    "DEBUG: Untangled - target push pop"
                }
            },
        },
        [s .. "10"] = {
            description = "two targets also in a group.",
            parameters = { "create", "the", "@glados", "lie" },
            expectations = {
                sequence = {
                    "DEBUG: Targets   - the @glados lie",
                    "DEBUG: Untangled - the cake lie"
                }
            },
        },
        [s .. "11"] = {
            description = "two targets also in a group, respects first appearance.",
            parameters = { "create", "lie", "cake", "@glados" },
            expectations = {
                sequence = {
                    "DEBUG: Targets   - lie cake @glados",
                    "DEBUG: Untangled - lie cake the"
                }
            },
        },
    },
}
