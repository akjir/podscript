-- PodConfig
return {
    -- Config Values
    name = "registry",

    -- Pod Values
    pod = {
        registry = "superpods.io",
    },

    containers = { "super", "mega" },
    -- Container Values
    container = {
        super = {
            detach = true,
            image = "super_container:latest",
        },
        mega = {
            detach = true,
            registry = "megapods.io",
            image = "mega_container:latest",
        },
    },
}