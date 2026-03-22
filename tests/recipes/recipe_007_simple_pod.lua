return {
    name = " Simple Pod  ",
    pod = {
        registry = "registry.io",
    },
    containers = {
        {
            name = " supR App  ",
            detach = true,
            restart = "never",
            image = "alpine:latest",
            volumes = {
                { "config", "/config", "Z" },
            },
        },
    }
}
