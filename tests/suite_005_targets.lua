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
                { 3, "ERROR: No targets set." },
            },
        },
        [s .. "02"] = {
            description = "Unknow target given.",
            parameters = { "create", "invalid" },
            expectations = {
                { 4, "ERROR: Target 'invalid' not found in config." },
            },
        },
        [s .. "03"] = {
            description = "Unknow group given.",
            parameters = { "create", "@invalid" },
            expectations = {
                { 4, "ERROR: Unknown recipe group '@invalid'." },
            },
        },
        [s .. "04"] = {
            description = "One target given.",
            parameters = { "create", "target" },
            expectations = {
                { 3, "DEBUG: Targets   - target" },
                { 4, "DEBUG: Untangled - target" },
            },
        },
        [s .. "05"] = {
            description = "One group given.",
            parameters = { "create", "@stack" },
            expectations = {
                { 3, "DEBUG: Targets   - @stack" },
                { 4, "DEBUG: Untangled - push pop" },
            },
        },
        [s .. "06"] = {
            description = "Three targets, but one is invalid.",
            parameters = { "create", "push", "invalid", "pop" },
            expectations = {
                { 3, "DEBUG: Targets   - push invalid pop" },
                { 4, "ERROR: Target 'invalid' not found in config." },
            },
        },
        [s .. "07"] = {
            description = "One target, one group.",
            parameters = { "create", "target", "@stack" },
            expectations = {
                { 3, "DEBUG: Targets   - target @stack" },
                { 4, "DEBUG: Untangled - target push pop" },
            },
        },
        [s .. "08"] = {
            description = "Same target twice.",
            parameters = { "create", "target", "target" },
            expectations = {
                { 3, "DEBUG: Targets   - target target" },
                { 4, "DEBUG: Untangled - target" },
            },
        },
        [s .. "09"] = {
            description = "Same target twice, one group.",
            parameters = { "create", "target", "@stack", "target" },
            expectations = {
                { 3, "DEBUG: Targets   - target @stack target" },
                { 4, "DEBUG: Untangled - target push pop" },
            },
        },
        [s .. "10"] = {
            description = "two targets also in a group.",
            parameters = { "create", "the", "@glados", "lie" },
            expectations = {
                { 3, "DEBUG: Targets   - the @glados lie" },
                { 4, "DEBUG: Untangled - the cake lie" },
            },
        },
        [s .. "11"] = {
            description = "two targets also in a group, respects first appearance.",
            parameters = { "create", "lie", "cake", "@glados" },
            expectations = {
                { 3, "DEBUG: Targets   - lie cake @glados" },
                { 4, "DEBUG: Untangled - lie cake the" },
            },
        },
    },
}
