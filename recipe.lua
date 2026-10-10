return {
    name = "Example Web Stack",
    description = "A minimal but complete example recipe with a web app and database.",

    pod = {
        name = "example-stack",
        path = "/pods/example-stack",
        registry = "docker.io",
        publish = {
            { 8080, 80, "TCP" },
        },
        commands = {
            migrate = {
                description = "Run database migrations.",
                container = "*db",
                user = "postgres",
                execute = "psql -U postgres -d app -f /migrations/run.sql",
            },
        },
        options = {
            "--userns=keep-id",
        },
    },

    containers = {
        {
            name = "*db",
            detach = true,
            restart = "always",
            registry = "docker.io",
            image = "postgres:15-alpine",
            volumes = {
                { "data", "/var/lib/postgresql/data", "Z" },
            },
            options = {
                "--env POSTGRES_PASSWORD=secret",
            },
        },
        {
            name = "*app",
            detach = true,
            restart = "always",
            image = "example/app:latest",
            commands = { "start-server.sh" },
        },
    },
}
