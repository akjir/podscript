-- PodConfig
return {
    -- Config Values
    name = "commands",

    -- Pod Values
    pod = {
        registry = "podreg.io";
    },

    -- Container Values
    containers = { "app" },
    container = {
        app = {
            image = "comands:latest",
            commands = {
                "command1",
                "command 2",
                "command3"
            }
        },
    },
}