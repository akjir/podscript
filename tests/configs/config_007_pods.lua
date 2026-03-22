return {
    simulate = true,
    pods = {
        path = "/pods",
    },
    recipes = {
        path = "tests/recipes",
        groups = {
            all = {
                "recipe_007_simple_pod",
            },
        },
    },
}
