return {
    name = " Simple Pod  ",
    pod = {
        name = "      si  po",
        registry = "registry.io",
    },
    containers = {
        {
            name = " supR App  ",
            restart = "never",
            image = "alpine:latest",
            volumes = {
                { "config", "/config", "Z" },
            },
        },
    }
}
