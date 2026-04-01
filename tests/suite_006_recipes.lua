local s = "006"
return {
    -- Tests for recipes.
    config = "config_005_recipes",
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Recipe not found. No path.",
            config = "config_004_targets",
            parameters = { "create", "target" },
            expectations = {
                { 5, "ERROR: cannot open ./target.lua: No such file or directory" },
                { 6, "ERROR: Couldn't load recipe './target.lua'!" },
            },
        },
        [s .. "02"] = {
            description = "Recipe not found. Path set.",
            parameters = { "create", "recipe_000_unkown" },
            expectations = {
                { 5, "ERROR: cannot open ./tests/recipes/recipe_000_unkown.lua: No such file or directory" },
                { 6, "ERROR: Couldn't load recipe './tests/recipes/recipe_000_unkown.lua'!" },
            },
        },
        [s .. "03"] = {
            description = "Recipe is empty. No name set.",
            parameters = { "create", "recipe_001_empty" },
            expectations = {
                { 5, "ERROR: No recipe name in recipe 'recipe_001_empty' set!" },
            },
        },
        [s .. "04"] = {
            description = "Pod section is missing.",
            parameters = { "create", "recipe_002_no_pod" },
            expectations = {
                { 5, "ERROR: Pod section in recipe 'recipe_002_no_pod' not defined! or empty" },
            },
        },
        [s .. "05"] = {
            description = "Pod section is empty.",
            parameters = { "create", "recipe_003_empty_pod" },
            expectations = {
                { 5, "ERROR: Pod section in recipe 'recipe_003_empty_pod' not defined! or empty" },
            },
        },
        [s .. "06"] = {
            description = "No default registry set in pod section.",
            parameters = { "create", "recipe_004_no_registry" },
            expectations = {
                { 5, "ERROR: No default registry in recipe 'recipe_004_no_registry' set or empty!" },
            },
        },
        [s .. "07"] = {
            description = "No default path and pod path set in pod section.",
            parameters = { "create", "recipe_005_no_path" },
            expectations = {
                { 5, "ERROR: No default pod path and pod path in recipe 'recipe_005_no_path' set or empty!" },
            },
        },
        [s .. "08"] = {
            description = "Only default path for pod path set.",
            config = "config_006_recipes_with_pod_path",
            parameters = { "create", "recipe_005_no_path" },
            expectations = {
                { 5, "INFO: No pod path in recipe 'recipe_005_no_path' set. Path '/pods/nopathpod' used." },
            },
        },
        [s .. "09"] = {
            description = "No containers section defined.",
            config = "config_006_recipes_with_pod_path",
            parameters = { "create", "recipe_006_no_containers" },
            expectations = {
                { 6, "ERROR: Container section in recipe 'recipe_006_no_containers' not defined or empty!" },
            },
        },
        [s .. "10"] = {
            description = "One empty Container.",
            config = "config_006_recipes_with_pod_path",
            parameters = { "create", "recipe_005_no_path" },
            expectations = {
                { 6, "ERROR: A container in pod 'nopathpod' is empty!" },
            },
        },
        [s .. "11"] = {
            description = "Use pod path '.'.",
            config = "config_009_same_directory",
            parameters = { "create", "target" },
            expectations = {
                { 6, "ERROR: cannot open ./target.lua: No such file or directory" },
                { 7, "ERROR: Couldn't load recipe './target.lua'!" },
            }
        },
        [s .. "12"] = {
            description = "Missing ',' in lua file.",
            parameters = { "create", "recipe_016_container_lua_error" },
            expectations = {
                { 5, "ERROR: ./tests/recipes/recipe_016_container_lua_error.lua:10: '}' expected (to close '{' at line 7) near 'image'" },
                { 6, "ERROR: Couldn't load recipe './tests/recipes/recipe_016_container_lua_error.lua'!" },
            }
        },
    },
}
