return {
    -- Tests for targets.
    config = "config_007_pods",
    tests = {
        T00701 = {
            description = "Create simple pod. Names are mixed case and have spaces and there is no pod path.",
            action = "create",
            targets = { "@nona" },
            expectations = {
                { 1, "INFO: Simulate mode is active." },
                { 2, "INFO: Config './tests/configs/config_007_pods.lua' is used." },
                { 3, "DEBUG: Targets   - @nona" },
                { 4, "DEBUG: Untangled - recipe_007_simple_pod_no_name_and_path" },
                { 5, "INFO: No pod path in recipe 'recipe_007_simple_pod_no_name_and_path' set. Path '/pods/simple_pod' used." },
                { 6, "Create pod 'Simple Pod' ..." },
                { 7, "podman pod create --name si__po;" },
            },
        },
    },
}
