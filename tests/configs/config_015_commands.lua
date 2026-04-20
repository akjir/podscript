return {
    pods = {
        path = "/tmp",
    },
    recipes = {
        path = "tests/recipes",
        groups = {
            all = {
                "recipe_006_commands",
                "recipe_011_simple_container",
                "recipe_021_no_description_commands",
            },
        },
    },
}
