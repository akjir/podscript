-- PodScript Config
return {
    -- Options
    dryrun = true, -- default is true to prevent unintentional executions

    -- PodConfigs Values
    configs = {
        path = ".",   -- path for pod config file
        cluster = {}, -- active pod configs, single use and with 'all', respects order
        single = {},  -- active pods config, only single use
    },

    -- Pod Values
    pods = {
        path = "/pods" -- default path for pod data
    },
}
