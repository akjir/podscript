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
                { 4, "ERROR: No targets set." },
            },
        },
        [s .. "02"] = {
            description = "Unknow target given.",
            parameters = { "create", "invalid" },
            expectations = {
                { 5, "ERROR: Target 'invalid' not found in config." },
            },
        },
        [s .. "03"] = {
            description = "Unknow group given.",
            parameters = { "create", "@invalid" },
            expectations = {
                { 5, "ERROR: Unknown recipe group '@invalid'." },
            },
        },
        [s .. "04"] = {
            description = "One target given.",
            parameters = { "create", "target" },
            expectations = {
                { 4, "DEBUG: Targets   - target" },
                { 5, "DEBUG: Untangled - target" },
            },
        },
        [s .. "05"] = {
            description = "One group given.",
            parameters = { "create", "@stack" },
            expectations = {
                { 4, "DEBUG: Targets   - @stack" },
                { 5, "DEBUG: Untangled - push pop" },
            },
        },
        [s .. "06"] = {
            description = "Three targets, but one is invalid.",
            parameters = { "create", "push", "invalid", "pop" },
            expectations = {
                { 4, "DEBUG: Targets   - push invalid pop" },
                { 5, "ERROR: Target 'invalid' not found in config." },
            },
        },
        [s .. "07"] = {
            description = "One target, one group.",
            parameters = { "create", "target", "@stack" },
            expectations = {
                { 4, "DEBUG: Targets   - target @stack" },
                { 5, "DEBUG: Untangled - target push pop" },
            },
        },
        [s .. "08"] = {
            description = "Same target twice.",
            parameters = { "create", "target", "target" },
            expectations = {
                { 4, "DEBUG: Targets   - target target" },
                { 5, "DEBUG: Untangled - target" },
            },
        },
        [s .. "09"] = {
            description = "Same target twice, one group.",
            parameters = { "create", "target", "@stack", "target" },
            expectations = {
                { 4, "DEBUG: Targets   - target @stack target" },
                { 5, "DEBUG: Untangled - target push pop" },
            },
        },
        [s .. "10"] = {
            description = "two targets also in a group.",
            parameters = { "create", "the", "@glados", "lie" },
            expectations = {
                { 4, "DEBUG: Targets   - the @glados lie" },
                { 5, "DEBUG: Untangled - the cake lie" },
            },
        },
        [s .. "11"] = {
            description = "two targets also in a group, respects first appearance.",
            parameters = { "create", "lie", "cake", "@glados" },
            expectations = {
                { 4, "DEBUG: Targets   - lie cake @glados" },
                { 5, "DEBUG: Untangled - lie cake the" },
            },
        },
    },
}
