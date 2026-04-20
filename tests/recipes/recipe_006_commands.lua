return {
    name = "commands_test",
    pod = {
        name = "cmd_pod",
        path = "/pod/path",
        registry = "test.io",
        commands = {
            add_index = {
                description = "Adds missing database indices.",
                container = "*db",
                user = "33",
                execute = "script.sh add-missing-indices",
            },
            run_absolute = {
                container = "absolute_db",
                execute = "script.sh run-absolute",
            },
            run_int_user = {
                container = "absolute_db",
                user = 1000,
                execute = "script.sh run-int-user",
            },
            run_int_container = {
                container = 1,
                execute = "script.sh run-int-container",
            },
            missing_container = {
                execute = "script.sh missing-container",
            },
            missing_execute = {
                container = "absolute_db",
            },
        },
    },
    containers = {
        { image = "test:latest" }
    },
}
