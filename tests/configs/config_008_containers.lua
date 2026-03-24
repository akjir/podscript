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
                "recipe_00B_simple_container",
                "recipe_00C_container_options",
                "recipe_00D_container_commands",
                "recipe_00E_registry_per_container",
                "recipe_00F_container_order",
                "recipe_011_container_naming",
            },
        },
    },
}
