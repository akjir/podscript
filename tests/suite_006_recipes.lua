return {
    -- Tests for targets.
    config = "config_005_recipes",
    tests = {
        T00601 = {
            description = "Recipe not found. No path.",
            config = "config_004_targets",
            action = "create",
            targets = { "target" },
            expectations = {
                { 4, "ERROR: Couldn't load Recipe './target.lua'!" },
            },
        },
        T00602 = {
            description = "Recipe not found. Path set.",
            action = "create",
            targets = { "recipe_000_unkown" },
            expectations = {
                { 4, "ERROR: Couldn't load Recipe './tests/recipes/recipe_000_unkown.lua'!" },
            },
        },
        T00603 = {
            description = "Recipe is empty. No name set.",
            action = "create",
            targets = { "recipe_001_empty" },
            expectations = {
                { 4, "ERROR: No recipe name in recipe 'recipe_001_empty' set!" },
            },
        },
    },
}
