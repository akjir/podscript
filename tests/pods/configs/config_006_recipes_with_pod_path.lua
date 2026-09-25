return {
    simulate = false,
    pods = {
        path = "/pods",
    },
    recipes = {
        path = "tests/pods/recipes",
        groups = {
            all = {
                "recipe_005_no_path",
                "recipe_006_no_containers",
            },
        },
    },
}
