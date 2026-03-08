-- PodScript Config
return {
    -- Options
        simulate = true,

    -- PodConfigs Values
    configs = {
        path = "./test_podconfigs",
        cluster = {},
        single = {
            "test_pc_registry",
            "test_pc_commands",
            "test_pc_publish",
        },
    },

    -- Pod Values
    pods = {
        path = "/pods"
    },
}
 