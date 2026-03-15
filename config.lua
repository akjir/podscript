-- PodScript Configuration
return {
    -- If true, commands will be printed but not executed.
    simulate = true,

    -- Pod-specific configurations.
    pods = {
        -- The default root directory for all pod-related data.
        path = "/pods",

        -- TODO
        -- registry - default registry for all recipes
        -- prefix - defines prefix. can be emtpy?
    },

    -- Defines where to find recipe files for pod creation.
    recipes = {
        -- The default search path for recipe files.
        path = ".",
        -- Defines groups of recipes that can be run together.
        -- All active recipes must be in a group.
        groups = {
            -- An example of a recipe group.
            all = {},
        },
    },
}
