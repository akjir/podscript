-- PodConfig
return {
    -- Config Values
    name = "commands",

    -- Pod Values
    pod = {
        registry = "podreg.io";
    },

    containers = { "app" },
    -- Container Values
    container = {
        app = {
            detach = true,
            image = "comands:latest",
            commands = {
                "command1",
                "command 2",
                "command3"
            }
        },
    },
}