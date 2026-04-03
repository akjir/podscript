local s = "012"
return {
    -- Tests for recipe mode.
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Print recipe help.",
            parameters = { "recipe", "help" },
            expectations = {
                { 4, "Usage: pods recipe [OPTIONS] ACTION NAME" },
            },
        },
        [s .. "02"] = {
            description = "Print recipe content.",
            config = "config_005_recipes",
            parameters = { "recipe", "print", "recipe_002_no_pod" },
            expectations = {
                { 6, "  1: return {" },
                { 7, "  2:     name = \"nopod\"," },
                { 8, "  3: }" },
            },
        },
        [s .. "03"] = {
            description = "Print for recipe not in config.",
            config = "config_005_recipes",
            parameters = { "recipe", "print", "unknown" },
            expectations = {
                { 5, "ERROR: Target 'unknown' not found in config." },
            },
        },
        [s .. "04"] = {
            description = "Print for recipe that doesn't exist on disk.",
            config = "config_005_recipes",
            parameters = { "recipe", "print", "recipe_000_unkown" },
            expectations = {
                { 6, "ERROR: Could not open file './tests/recipes/recipe_000_unkown.lua'!" },
            },
        },
        [s .. "05"] = {
            description = "Recipe with unknown action.",
            config = "config_005_recipes",
            parameters = { "recipe", "unknown", "recipe_002_no_pod" },
            expectations = {
                { 4, "ERROR: Unknown action: unknown" },
            },
        },
        [s .. "06"] = {
            description = "Recipe with missing name.",
            config = "config_005_recipes",
            parameters = { "recipe", "print" },
            expectations = {
                { 4, "ERROR: No recipe name given." },
            },
        },
        [s .. "07"] = {
            description = "Recipe with missing action.",
            config = "config_005_recipes",
            parameters = { "recipe" },
            expectations = {
                { 4, "ERROR: No action given." },
            },
        },
    }
}
