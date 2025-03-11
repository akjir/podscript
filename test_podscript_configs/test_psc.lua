-- PodScript Config
return {
    -- Options
    dryrun = true,

    -- PodConfigs Values
    configs = {
        path = "./test_podconfigs",
        cluster = {},
        single = {
            "test_pc_registry",
            "test_pc_commands",
        },
    },

    -- Pod Values
    pods = {
        path = "/pods"
    },
}
 