return {
    name = "Simple Container",
    pod = {
        registry = "simple.io",
    },
    containers = {
        {
            ---@diagnostic disable-next-line: miss-sep-in-table
            name = "simple"
            image = "simple:latest",
        },
    },
}
