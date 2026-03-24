return {
    -- Tests for recipes.
    config = "config_005_recipes",
    tests = {
        T00601 = {
            description = "Recipe not found. No path.",
            config = "config_004_targets",
            action = "create",
            targets = { "target" },
            expectations = {
                { 4, "ERROR: cannot open ./target.lua: No such file or directory" },
                { 5, "ERROR: Couldn't load recipe './target.lua'!" },
            },
        },
        T00602 = {
            description = "Recipe not found. Path set.",
            action = "create",
            targets = { "recipe_000_unkown" },
            expectations = {
                { 4, "ERROR: cannot open ./tests/recipes/recipe_000_unkown.lua: No such file or directory" },
                { 5, "ERROR: Couldn't load recipe './tests/recipes/recipe_000_unkown.lua'!" },
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
        T00604 = {
            description = "Pod section is missing.",
            action = "create",
            targets = { "recipe_002_no_pod" },
            expectations = {
                { 4, "ERROR: Pod section in recipe 'recipe_002_no_pod' not defined! or empty" },
            },
        },
        T00605 = {
            description = "Pod section is empty.",
            action = "create",
            targets = { "recipe_003_empty_pod" },
            expectations = {
                { 4, "ERROR: Pod section in recipe 'recipe_003_empty_pod' not defined! or empty" },
            },
        },
        T00606 = {
            description = "No default registry set in pod section.",
            action = "create",
            targets = { "recipe_004_no_registry" },
            expectations = {
                { 4, "ERROR: No default registry in recipe 'recipe_004_no_registry' set or empty!" },
            },
        },
        T00607 = {
            description = "No default path and pod path set in pod section.",
            action = "create",
            targets = { "recipe_005_no_path" },
            expectations = {
                { 4, "ERROR: No default pod path and pod path in recipe 'recipe_005_no_path' set or empty!" },
            },
        },
        T00608 = {
            description = "Only default path for pod path set.",
            config = "config_006_recipes_with_pod_path",
            action = "create",
            targets = { "recipe_005_no_path" },
            expectations = {
                { 4, "INFO: No pod path in recipe 'recipe_005_no_path' set. Path '/pods/nopathpod' used." },
            },
        },
        T00609 = {
            description = "No containers section defined.",
            config = "config_006_recipes_with_pod_path",
            action = "create",
            targets = { "recipe_006_no_containers" },
            expectations = {
                { 5, "ERROR: Container section in recipe 'recipe_006_no_containers' not defined or empty!" },
            },
        },
        T0060A = {
            description = "One empty Container.",
            config = "config_006_recipes_with_pod_path",
            action = "create",
            targets = { "recipe_005_no_path" },
            expectations = {
                { 5, "ERROR: A container in pod 'pod-nopathpod' is empty!" },
            },
        },
        T0060B = {
            description = "Use pod path '.'.",
            config = "config_009_same_directory",
            action = "create",
            targets = { "target" },
            expectations = {
                { 5, "ERROR: cannot open ./target.lua: No such file or directory" },
                { 6, "ERROR: Couldn't load recipe './target.lua'!" },
            }
        },
        T0060C = {
            description = "Missing ',' in lua file.",
            action = "create",
            targets = { "recipe_010_container_lua_error" },
            expectations = {
                { 4, "ERROR: ./tests/recipes/recipe_010_container_lua_error.lua:10: '}' expected (to close '{' at line 7) near 'image'" },
                { 5, "ERROR: Couldn't load recipe './tests/recipes/recipe_010_container_lua_error.lua'!" },
            }
        },
    },
}
