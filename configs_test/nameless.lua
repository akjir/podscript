-- PodConfig
return {
    -- Config Values
    name = "nameless", -- name for the confg

    -- Pod Values
    pod = {
        registry = "superpods.io",
        commands = {
            "--publish 8088:80/tcp",
        },
    },

    containers = { "app" },
    -- Container Values
    container = {
        app = {
            detach = true,
            image = "nameless:latest",
        },
    },
}
