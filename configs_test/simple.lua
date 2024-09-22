-- PodConfig
local name = "simple"
local pod_name = "pod-" .. name
return {
    -- Config Values
    name = name,                -- name for the confg
    description = "simple pod", -- description

    -- Pod Values
    pod = {
        name = pod_name,
        registry = "superpods.io",
        commands = {
            "--publish 8081:80/tcp",
        },
    },

    -- Container Values
    containers = { "app" },
    container = {
        app = {
            name = pod_name .. "-app",
            detach = true,
            restart = "never",
            image = "simple/simple:latest",
            volumes = {
                {}, -- invalid
                { "invalid" },
                { "data",       "/internal/data",   "Z" },
                { "config",     "/special/config:Z" },
                { "/mnt/media", "/special/media" },
            },
        },
    },
}
