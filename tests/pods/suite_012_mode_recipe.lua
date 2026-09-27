local s = "012"
return {
    -- Tests for recipe mode.
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Print recipe help.",
            parameters = { "recipe", "help" },
            expectations = {
                sequence = {
                    "Usage: pods recipe [OPTIONS] ACTION NAME"
                }
            },
        },
        [s .. "02"] = {
            description = "Print recipe content.",
            config = "config_005_recipes",
            parameters = { "recipe", "print", "recipe_002_no_pod" },
            expectations = {
                sequence = {
                    "  1: return {",
                    "  2:     name = \"nopod\",",
                    "  3: }"
                }
            },
        },
        [s .. "03"] = {
            description = "Print for recipe not in config.",
            config = "config_005_recipes",
            parameters = { "recipe", "print", "unknown" },
            expectations = {
                sequence = {
                    "ERROR: Recipe 'unknown' not found in config."
                }
            },
        },
        [s .. "04"] = {
            description = "Print for recipe that doesn't exist on disk.",
            config = "config_005_recipes",
            parameters = { "recipe", "print", "recipe_000_unkown" },
            expectations = {
                sequence = {
                    "ERROR: Could not open file './tests/pods/recipes/recipe_000_unkown.lua'!"
                }
            },
        },
        [s .. "05"] = {
            description = "Recipe with unknown action.",
            config = "config_005_recipes",
            parameters = { "recipe", "unknown", "recipe_002_no_pod" },
            expectations = {
                sequence = {
                    "ERROR: Unknown action: unknown"
                }
            },
        },
        [s .. "06"] = {
            description = "Recipe with missing name.",
            config = "config_005_recipes",
            parameters = { "recipe", "print" },
            expectations = {
                sequence = {
                    "ERROR: No recipe name given."
                }
            },
        },
        [s .. "07"] = {
            description = "Print recipe help without action.",
            parameters = { "recipe" },
            expectations = {
                sequence = {
                    "Usage: pods recipe [OPTIONS] ACTION NAME"
                }
            },
        },
        [s .. "08"] = {
            description = "Edit recipe with no editor configured.",
            config = "config_014_recipe_edit_no_editor",
            parameters = { "recipe", "edit", "recipe_002_no_pod" },
            expectations = {
                sequence = {
                    "ERROR: No editor configured."
                }
            },
        },
        [s .. "09"] = {
            description = "Edit recipe simulation.",
            config = "config_013_recipe_edit",
            parameters = { "recipe", "edit", "recipe_002_no_pod" },
            expectations = {
                sequence = {
                    "DEBUG: Execute: editor ./tests/pods/recipes/recipe_002_no_pod.lua;",
                    "ERROR: Command exited with code '127'!"
                }
            },
        },
        [s .. "10"] = {
            description = "Edit recipe with missing name.",
            config = "config_013_recipe_edit",
            parameters = { "recipe", "edit" },
            expectations = {
                sequence = {
                    "ERROR: No recipe name given."
                }
            },
        },
        [s .. "11"] = {
            description = "List recipes defined in config.",
            config = "config_016_recipe_list",
            parameters = { "recipe", "list" },
            expectations = {
                sequence = {
                    "Recipes:",
                    "  1) recipe_011_simple_container (Simple Container)",
                    "  2) recipe_022_description (Super Pod): Super Pod is great"
                }
            },
        },
        [s .. "12"] = {
            description = "List recipes when no recipes defined.",
            config = "config_003_simulate_true",
            parameters = { "recipe", "list" },
            expectations = {
                sequence = {
                    "There are no recipes defined in config."
                }
            },
        },
    }
}
