return {
    name = "options",
    pod = {
        registry = "options.io",
        options = {
            "--network slirp4netns:port_handler=slirp4netns",
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
