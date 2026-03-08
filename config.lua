-- PodScript Configuration
return {
    -- If true, commands will be printed but not executed.
    dryrun = true,

    -- Defines where to find recipe files for pod creation.
    recipes = {
        -- The default search path for recipe files.
        path = ".",
        -- Defines groups of recipes that can be run together. All active recipes must be in a group.
        groups = {
            -- An example of a recipe group.
            all = {},
        },
    },

    -- Pod-specific configurations.
    pods = {
        -- The default root directory for all pod-related data.
        path = "/pods",
    },
}
