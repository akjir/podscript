local s = "012"
return {
    -- Tests for recipe mode.
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Show recipe help.",
            parameters = { "recipe", "help" },
            expectations = {
                sequence = {
                    "Usage: pods recipe [OPTIONS] ACTION NAME"
                }
            },
        },
        [s .. "02"] = {
            description = "Show recipe content.",
            config = "config_005_recipes",
            parameters = { "recipe", "show", "recipe_002_no_pod" },
            expectations = {
                sequence = {
                    "  1: return {",
                    "  2:     name = \"nopod\",",
                    "  3: }"
                }
            },
        },
        [s .. "03"] = {
            description = "Show for recipe not in config.",
            config = "config_005_recipes",
            parameters = { "recipe", "show", "unknown" },
            expectations = {
                sequence = {
                    "ERROR: Recipe 'unknown' not found in configuration!"
                }
            },
        },
        [s .. "04"] = {
            description = "Show for recipe that doesn't exist on disk.",
            config = "config_005_recipes",
            parameters = { "recipe", "show", "recipe_000_unkown" },
            expectations = {
                sequence = {
                    "ERROR: Could not open file './tests/pods/recipes/recipe_000_unkown.lua'!"
                }
            },
        },
        [s .. "05"] = {
            description = "Show recipe implicitly without action.",
            config = "config_005_recipes",
            parameters = { "recipe", "recipe_002_no_pod" },
            expectations = {
                sequence = {
                    "  1: return {",
                    "  2:     name = \"nopod\",",
                    "  3: }"
                }
            },
        },
        [s .. "06"] = {
            description = "Recipe with missing name.",
            config = "config_005_recipes",
            parameters = { "recipe", "show" },
            expectations = {
                sequence = {
                    "ERROR: No recipe name given."
                }
            },
        },
        [s .. "07"] = {
            description = "List recipes implicitly without action.",
            config = "config_016_recipe_list",
            parameters = { "recipe" },
            expectations = {
                sequence = {
                    "Recipes:",
                    "  1) recipe_011_simple_container (Simple Container)",
                    "  2) recipe_022_description (Super Pod): Super Pod is great"
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
                    "DEBUG: Execute: false ./tests/pods/recipes/recipe_002_no_pod.lua",
                    "ERROR: Command exited with code '1'!"
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
        [s .. "13"] = {
            description = "List recipes with --all for fully synced config.",
            config = "config_016_recipe_list",
            parameters = { "recipe", "list", "--all" },
            expectations = {
                sequence = {
                    "Recipes:",
                    "  1) recipe_011_simple_container (Simple Container)",
                    "  2) recipe_022_description (Super Pod): Super Pod is great",
                    "Unlinked Recipe Files:",
                    "[UNREFERENCED]"
                }
            },
        },
        [s .. "14"] = {
            description = "List recipes validation formatting.",
            config = "config_013_validation",
            parameters = { "recipe", "list", "--all" },
            expectations = {
                sequence = {
                    "Recipes:",
                    "frontend                              [NOT FOUND]",
                    "missing_recipe                        [NOT FOUND]",
                    "recipe_001_empty                      [OK]",
                    "Unlinked Recipe Files:",
                    "[UNREFERENCED]"
                }
            },
        },
        [s .. "15"] = {
            description = "List recipes default missing validation format.",
            config = "config_013_validation",
            parameters = { "recipe", "list" },
            expectations = {
                sequence = {
                    "Recipes:",
                    "frontend                               [NOT FOUND]",
                    "missing_recipe                         [NOT FOUND]",
                    "recipe_001_empty                       [OK]"
                },
                not_contains = {
                    "Unlinked Recipe Files:",
                    "[UNREFERENCED]"
                }
            },
        },
    }
}
