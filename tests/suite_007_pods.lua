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
                { 8, "podman run --name supr_app --pod si__po --detach --restart never --volume /pods/simple_pod/config:/config:Z registry.io/alpine:latest;" },
            },
        },
        T00702 = {
            description = "Remove simple pod. Names are mixed case and have spaces and there is no pod path.",
            action = "remove",
            targets = { "@nona" },
            expectations = {
                { 6, "Remove pod 'Simple Pod' ..." },
                { 7, "podman stop supr_app;" },
                { 8, "podman rm supr_app;" },
                { 9, "podman pod rm si__po;" },
            },
        },
        T00703 = {
            description = "Update simple pod. Names are mixed case and have spaces and there is no pod path.",
            action = "update",
            targets = { "@nona" },
            expectations = {
                { 6, "Update pod 'Simple Pod' ..." },
                { 7, "podman pull registry.io/alpine:latest;" },
            },
        },
        T00704 = {
            description = "Recreate simple pod. Names are mixed case and have spaces and there is no pod path.",
            action = "recreate",
            targets = { "@nona" },
            expectations = {
                { 6,  "Remove pod 'Simple Pod' ..." },
                { 10, "Create pod 'Simple Pod' ..." },
            },
        },
        T00705 = {
            description = "Test for publish.",
            action = "create",
            targets = { "recipe_008_publish" },
            expectations = {
                { 7, "podman pod create --name pod-publish --publish 8433:433 --publish 8080:80/TCP --publish 127.0.0.1::42 --publish 127.0.0.1:62:43/UDP --publish 600-500 --publish 83 --publish 124 --publish 12/UDP;" },
            },
        },
    },
}
