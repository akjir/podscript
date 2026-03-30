return {
    -- Tests for targets.
    config = "config_004_targets",
    tests = {
        T00501 = {
            description = "No targets given as arguments.",
            action = "create",
            expectations = {
                { 2, "ERROR: No targets set." },
            },
        },
        T00502 = {
            description = "Unknow target given.",
            action = "create",
            targets = { "invalid" },
            expectations = {
                { 3, "ERROR: Target 'invalid' not found in config." },
            },
        },
        T00503 = {
            description = "Unknow group given.",
            action = "create",
            targets = { "@invalid" },
            expectations = {
                { 3, "ERROR: Unknown recipe group '@invalid'." },
            },
        },
        T00504 = {
            description = "One target given.",
            action = "create",
            targets = { "target" },
            expectations = {
                { 2, "DEBUG: Targets   - target" },
                { 3, "DEBUG: Untangled - target" },
            },
        },
        T00505 = {
            description = "One group given.",
            action = "create",
            targets = { "@stack" },
            expectations = {
                { 2, "DEBUG: Targets   - @stack" },
                { 3, "DEBUG: Untangled - push pop" },
            },
        },
        T00506 = {
            description = "Three targets, but one is invalid.",
            action = "create",
            targets = { "push", "invalid", "pop" },
            expectations = {
                { 2, "DEBUG: Targets   - push invalid pop" },
                { 3, "ERROR: Target 'invalid' not found in config." },
            },
        },
        T00507 = {
            description = "One target, one group.",
            action = "create",
            targets = { "target", "@stack" },
            expectations = {
                { 2, "DEBUG: Targets   - target @stack" },
                { 3, "DEBUG: Untangled - target push pop" },
            },
        },
        T00508 = {
            description = "Same target twice.",
            action = "create",
            targets = { "target", "target" },
            expectations = {
                { 2, "DEBUG: Targets   - target target" },
                { 3, "DEBUG: Untangled - target" },
            },
        },
        T00509 = {
            description = "Same target twice, one group.",
            action = "create",
            targets = { "target", "@stack", "target" },
            expectations = {
                { 2, "DEBUG: Targets   - target @stack target" },
                { 3, "DEBUG: Untangled - target push pop" },
            },
        },
        T00510 = {
            description = "two targets also in a group.",
            action = "create",
            targets = { "the", "@glados", "lie" },
            expectations = {
                { 2, "DEBUG: Targets   - the @glados lie" },
                { 3, "DEBUG: Untangled - the cake lie" },
            },
        },
        T00511 = {
            description = "two targets also in a group, respects first appearance.",
            action = "create",
            targets = { "lie", "cake", "@glados" },
            expectations = {
                { 2, "DEBUG: Targets   - lie cake @glados" },
                { 3, "DEBUG: Untangled - lie cake the" },
            },
        },
    },
}
