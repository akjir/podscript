-- PodConfig
return {
    -- Config Values
    name = "options",

    -- Pod Values
    pod = {
        registry = "podreg.io";
        options = {
            "--option1",
            "--option2 value",
        },
    },

    containers = { "app" },
    -- Container Values
    container = {
        app = {
            detach = true,
            image = "optional:latest",
            options = {
                "--option1",
                "--option2 value",
            },
        },
    },
}