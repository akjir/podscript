return {
    name = "Con Name",
    pod = {
        registry = "registry.io",
    },
    containers = {
        {
            name = "absolute",
            image = "name:latest",
        },
        {
            name = "*relative",
            image = "name:latest",
        },
    },
}
