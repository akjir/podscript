-- PodScript Config
return {
    -- Options
    dryrun = true,

    -- PodConfigs Values
    configs = {
        path = "./configs_test",
        cluster = { "simple", "invalid", "registry", "options", "commands" },
        single = { "notfound", "nameless" },
    },

    -- Pod Values
    pods = {
        path = "/pods"
    },
}
