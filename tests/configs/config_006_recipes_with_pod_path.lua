return {
    simulate = false,
    pods = {
        path = "/pods",
    },
    recipes = {
        path = "tests/recipes",
        groups = {
            all = {
                "recipe_005_no_path",
                "recipe_006_no_containers",
            },
        },
    },
}
