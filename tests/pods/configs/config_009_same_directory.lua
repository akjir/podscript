return {
    simulate = true,
    pods = {
        path = "/pods",
    },
    recipes = {
        path = ".",
        groups = {
            single = {
                "target",
            },
        },
    },
}
