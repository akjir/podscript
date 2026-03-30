return {
    name = "Simple Container",
    pod = {
        registry = "simple.io",
    },
    containers = {
        {
            name = "simple",
            image = "simple:latest",
        },
    },
}
