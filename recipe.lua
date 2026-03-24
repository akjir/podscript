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
            name = "simple",
            image = "simple:latest",
        },
    },
}
