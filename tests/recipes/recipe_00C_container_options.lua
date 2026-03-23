return {
    name = "Copti",
    pod = {
        registry = "conop.io",
    },
    containers = {
        {
            name = "snoitop",
            options = {
                "--unknown thing",
                "--another unknown",
            },
            image = "simple:latest",
        },
    },
}
