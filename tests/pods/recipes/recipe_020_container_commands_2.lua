return {
    name = "Command Example",
    pod = {
        name = "cmd_test",
        registry = "registry.io",
    },
    containers = {
        {
            name = "cmd_con",
            image = "alpine:latest",
            commands = { "sh", "-c", "echo 'hello world'" },
        },
    },
}
