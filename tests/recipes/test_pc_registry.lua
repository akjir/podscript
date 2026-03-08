-- PodConfig
return {
    -- Config Values
    name = "registry",

    -- Pod Values
    pod = {
        registry = "superpods.io",
    },

    -- Container Values
    containers = { "super", "mega" },
    container = {
        super = {
            image = "super_container:latest",
        },
        mega = {
            registry = "megapods.io",
            image = "mega_container:latest",
        },
    },
}