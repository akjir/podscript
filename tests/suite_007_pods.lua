return {
    -- Tests for targets.
    config = "config_007_pods",
    tests = {
        T00701 = {
            description = "Create simple pod. Names are mixed case and have spaces.",
            action = "create",
            targets = { "@all" },
            expectations = {
                { 1, "INFO: Simulate mode is active." },
                { 2, "INFO: Config './tests/configs/config_007_pod.lua' is used." },
                { 3, "DEBUG: Targets   - @all" },
                { 4, "DEBUG: Untangled - recipe_007_simple_pod" },
                { 5, "INFO: No pod path in recipe 'recipe_007_simple_pod' set. Path '/pods/simple_pod' used." },
                { 6, "Create pod 'Simple Pod' ..." },
                { 7, "podman pod create --name pod-simple_pod;" },
            },
        },
    },
}
