-- Example recipe.
return {
    -- Recipe values.
    -- Name for the Recipe.
    name = "Example Container",
    -- Pod section.
    pod = {
        -- Name of pod. Will be pod_name.
        name = "Pod name",
        -- Default registry for containers.
        registry = "registry.io",
        -- Ports to publish.
        publish = {
            { 8433, 433 },
            { 8080, 80, "TCP" },
        },
        -- Raw options.
        options = {
            "--userns=host",
            "--tty",
        },
    },
    containers = {
        { -- 1
            -- Absolute name of the container
            name = "simple",
            -- Detached mode.
            detach = true,
            -- Restart policy.
            restart = "never",
            -- Image to use.
            image = "simple:latest",
        },
        { -- 2
            -- Missing name will use pod name
            -- Will be pod_name-2
            detach = true,
            restart = "always",
            -- Separate registry for this container.
            registry = "another-registry.io",
            image = "simple2:latest",
            volumes = {
                { "file.conf", "/path/file.conf", "ro,Z" },
                { "folder",    "/path/folder",    "Z" },
            },
        },
        {
            -- Relative name for container
            -- Will be pod_name-db
            name = "*db",
            detach = true,
            restart = "on-failure",
            image = "simple3:1.1",
            options = {
                "--env ADMIN_TOKEN='1234567890'",
            },
        },
    },
}
