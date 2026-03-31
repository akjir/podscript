return {
    -- Tests for targets.
    config = "config_004_targets",
    tests = {
        T00501 = {
            description = "No targets given as arguments.",
            action = "create",
            expectations = {
                { 3, "ERROR: No targets set." },
            },
        },
        T00502 = {
            description = "Unknow target given.",
            action = "create",
            targets = { "invalid" },
            expectations = {
                { 4, "ERROR: Target 'invalid' not found in config." },
            },
        },
        T00503 = {
            description = "Unknow group given.",
            action = "create",
            targets = { "@invalid" },
            expectations = {
                { 4, "ERROR: Unknown recipe group '@invalid'." },
            },
        },
        T00504 = {
            description = "One target given.",
            action = "create",
            targets = { "target" },
            expectations = {
                { 3, "DEBUG: Targets   - target" },
                { 4, "DEBUG: Untangled - target" },
            },
        },
        T00505 = {
            description = "One group given.",
            action = "create",
            targets = { "@stack" },
            expectations = {
                { 3, "DEBUG: Targets   - @stack" },
                { 4, "DEBUG: Untangled - push pop" },
            },
        },
        T00506 = {
            description = "Three targets, but one is invalid.",
            action = "create",
            targets = { "push", "invalid", "pop" },
            expectations = {
                { 3, "DEBUG: Targets   - push invalid pop" },
                { 4, "ERROR: Target 'invalid' not found in config." },
            },
        },
        T00507 = {
            description = "One target, one group.",
            action = "create",
            targets = { "target", "@stack" },
            expectations = {
                { 3, "DEBUG: Targets   - target @stack" },
                { 4, "DEBUG: Untangled - target push pop" },
            },
        },
        T00508 = {
            description = "Same target twice.",
            action = "create",
            targets = { "target", "target" },
            expectations = {
                { 3, "DEBUG: Targets   - target target" },
                { 4, "DEBUG: Untangled - target" },
            },
        },
        T00509 = {
            description = "Same target twice, one group.",
            action = "create",
            targets = { "target", "@stack", "target" },
            expectations = {
                { 3, "DEBUG: Targets   - target @stack target" },
                { 4, "DEBUG: Untangled - target push pop" },
            },
        },
        T00510 = {
            description = "two targets also in a group.",
            action = "create",
            targets = { "the", "@glados", "lie" },
            expectations = {
                { 3, "DEBUG: Targets   - the @glados lie" },
                { 4, "DEBUG: Untangled - the cake lie" },
            },
        },
        T00511 = {
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
