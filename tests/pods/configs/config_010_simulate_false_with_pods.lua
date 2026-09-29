return {
    simulate = false,
    pods = {
        path = "/pods",
    },
    recipes = {
        path = "tests/pods/recipes",
        groups = {
            nona = {
                "recipe_007_simple_pod_no_name_and_path",
            },
        },
    },
}
