return {
    name = "no_description_commands",
    pod = {
        name = "test_pod",
        path = "/tmp",
        registry = "test.io",
        commands = {
            cmd1 = { execute = "sh cmd1.sh" },
            cmd2 = { execute = "sh cmd2.sh" },
        },
    },
    containers = {
        {
            image = "test:latest",
        },
    },
}
