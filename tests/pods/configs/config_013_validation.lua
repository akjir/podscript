return {
    editor = "vim",
    simulate = false,
    pods = {
        path = "/tmp/non_existent_pods_dir"
    },
    recipes = {
        path = "./tests/pods/recipes",
        groups = {
            all = { "missing_recipe" },
            stack = { "@database", "@web" },
            database = { "recipe_001_empty" },
            web = { "frontend" }
        }
    }
}
