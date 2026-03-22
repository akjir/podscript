return {
    name = "Simple Pod",
    pod = {
        registry = "registry.io",
    },
    containers = {
        {
            name = "app",
            detach = true,
            restart = "never",
            image = "alpine",
            volumes = {
                { "config", "/config", "Z" },
            },
        },
    }
}
