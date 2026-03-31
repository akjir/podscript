local s = "005"
return {
    -- Tests for targets.
    config = "config_004_targets",
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "No targets given as arguments.",
            action = "create",
            expectations = {
                { 3, "ERROR: No targets set." },
            },
        },
        [s .. "02"] = {
            description = "Unknow target given.",
            action = "create",
            targets = { "invalid" },
            expectations = {
                { 4, "ERROR: Target 'invalid' not found in config." },
            },
        },
        [s .. "03"] = {
            description = "Unknow group given.",
            action = "create",
            targets = { "@invalid" },
            expectations = {
                { 4, "ERROR: Unknown recipe group '@invalid'." },
            },
        },
        [s .. "04"] = {
            description = "One target given.",
            action = "create",
            targets = { "target" },
            expectations = {
                { 3, "DEBUG: Targets   - target" },
                { 4, "DEBUG: Untangled - target" },
            },
        },
        [s .. "05"] = {
            description = "One group given.",
            action = "create",
            targets = { "@stack" },
            expectations = {
                { 3, "DEBUG: Targets   - @stack" },
                { 4, "DEBUG: Untangled - push pop" },
            },
        },
        [s .. "06"] = {
            description = "Three targets, but one is invalid.",
            action = "create",
            targets = { "push", "invalid", "pop" },
            expectations = {
                { 3, "DEBUG: Targets   - push invalid pop" },
                { 4, "ERROR: Target 'invalid' not found in config." },
            },
        },
        [s .. "07"] = {
            description = "One target, one group.",
            action = "create",
            targets = { "target", "@stack" },
            expectations = {
                { 3, "DEBUG: Targets   - target @stack" },
                { 4, "DEBUG: Untangled - target push pop" },
            },
        },
        [s .. "08"] = {
            description = "Same target twice.",
            action = "create",
            targets = { "target", "target" },
            expectations = {
                { 3, "DEBUG: Targets   - target target" },
                { 4, "DEBUG: Untangled - target" },
            },
        },
        [s .. "09"] = {
            description = "Same target twice, one group.",
            action = "create",
            targets = { "target", "@stack", "target" },
            expectations = {
                { 3, "DEBUG: Targets   - target @stack target" },
                { 4, "DEBUG: Untangled - target push pop" },
            },
        },
        [s .. "10"] = {
            description = "two targets also in a group.",
            action = "create",
            targets = { "the", "@glados", "lie" },
            expectations = {
                { 3, "DEBUG: Targets   - the @glados lie" },
                { 4, "DEBUG: Untangled - the cake lie" },
            },
        },
        [s .. "11"] = {
            description = "two targets also in a group, respects first appearance.",
            action = "create",
            targets = { "lie", "cake", "@glados" },
            expectations = {
                { 3, "DEBUG: Targets   - lie cake @glados" },
                { 4, "DEBUG: Untangled - lie cake the" },
            },
        },
    },
}
