return {
    name = "options",
    pod = {
        registry = "options.io",
        options = {
            "--some thing",
            "--another thing"
        },
    },
    containers = {
        {
            name = "options",
            image = "options:latest",
        },
    },
}
