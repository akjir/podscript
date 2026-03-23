return {
    simulate = true,
    pods = {
        path = "/pods",
    },
    recipes = {
        path = "tests/recipes",
        groups = {
            nona = {
                "recipe_007_simple_pod_no_name_and_path",
            },
            tests = {
                "recipe_008_publish",
                "recipe_00A_pod_options",
            },
        },
    },
}
