return {
    name = "Copti",
    pod = {
        registry = "conop.io",
    },
    containers = {
        {
            name = "snoitpo",
            detach = false,
            options = {
                "--unknown thing",
                "--another unknown",
            },
            image = "simple:latest",
        },
    },
}
