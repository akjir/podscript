return {
    -- Tests for pods.
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
                { 5, "INFO: No pod path in recipe 'recipe_007_simple_pod_no_name_and_path' set. Path '/pods/si_po' used." },
                { 6, "Create pod 'Simple Pod' ('si_po'): " },
                { 7, "podman pod create --name si_po;" },
                { 8, "Create container 'supr_app': " },
                { 9, "podman run --name supr_app --pod si_po --detach --restart never --volume config:/config:Z registry.io/alpine:latest;" },
            },
        },
        T00702 = {
            description = "Remove simple pod. Names are mixed case and have spaces and there is no pod path.",
            action = "remove",
            targets = { "@nona" },
            expectations = {
                { 6,  "Stop container 'supr_app': " },
                { 7,  "podman stop supr_app;" },
                { 8,  "Remove container 'supr_app': " },
                { 9,  "podman rm supr_app;" },
                { 10, "Remove pod 'Simple Pod' ('si_po'): " },
                { 11, "podman pod rm si_po;" },
            },
        },
        T00703 = {
            description = "Update simple pod. Names are mixed case and have spaces and there is no pod path.",
            action = "update",
            targets = { "@nona" },
            expectations = {
                { 6, "Update pod 'Simple Pod' ('si_po') ..." },
                { 7, "Update container 'supr_app' ..." },
                { 8, "podman pull registry.io/alpine:latest;" },
            },
        },
        T00704 = {
            description = "Recreate simple pod. Names are mixed case and have spaces and there is no pod path.",
            action = "recreate",
            targets = { "@nona" },
            expectations = {
                { 10, "Remove pod 'Simple Pod' ('si_po'): " },
                { 12, "Create pod 'Simple Pod' ('si_po'): " },
            },
        },
        T00705 = {
            description = "Test for publish.",
            action = "create",
            targets = { "recipe_008_publish" },
            expectations = {
                { 7, "podman pod create --name publish --publish 8433:433 --publish 8080:80/TCP --publish 127.0.0.1::42 --publish 127.0.0.1:62:43/UDP --publish 600-500 --publish 83 --publish 124 --publish 12/UDP;" },
            },
        },
        T00706 = {
            description = "Test for options.",
            action = "create",
            targets = { "recipe_00A_pod_options" },
            expectations = {
                { 7, "podman pod create --name options --some thing --another thing;" },
            },
        },
    },
}
