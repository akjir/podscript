return {
    simulate = true,
    pods = {
        path = "/pods",
    },
    recipes = {
        path = "tests/recipes",
        groups = {
            tests = {
                "recipe_009_no_registry",
                "recipe_011_simple_container",
                "recipe_012_container_options",
                "recipe_013_container_commands",
                "recipe_014_registry_per_container",
                "recipe_015_container_order",
                "recipe_017_container_naming",
                "recipe_018_container_volumes",
                "recipe_019_container_volumes_with_no_path",
                "recipe_020_container_commands_2",
            },
        },
    },
}
