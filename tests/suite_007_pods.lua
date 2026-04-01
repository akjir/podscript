local s = "007"
return {
    -- Tests for pods.
    config = "config_007_pods",
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Create simple pod. Names are mixed case and have spaces and there is no pod path.",
            parameters = { "create", "@nona" },
            expectations = {
                { 1,  "DEBUG: Debug mode is enabled." },
                { 2,  "DEBUG: Config './tests/configs/config_007_pods.lua' is used." },
                { 3,  "INFO: Simulate mode is active." },
                { 4,  "DEBUG: Targets   - @nona" },
                { 5,  "DEBUG: Untangled - recipe_007_simple_pod_no_name_and_path" },
                { 6,  "INFO: No pod path in recipe 'recipe_007_simple_pod_no_name_and_path' set. Path '/pods/si_po' used." },
                { 7,  "Create pod 'Simple Pod' ('si_po'): " },
                { 8,  "podman pod create --name si_po;" },
                { 9,  "Create container 'supr_app': " },
                { 10, "podman run --name supr_app --pod si_po --detach --restart never --volume /pods/si_po/config:/config:Z registry.io/alpine:latest;" },
            },
        },
        [s .. "02"] = {
            description = "Remove simple pod. Names are mixed case and have spaces and there is no pod path.",
            parameters = { "remove", "@nona" },
            expectations = {
                { 7,  "Stop container 'supr_app': " },
                { 8,  "podman stop supr_app;" },
                { 9,  "Remove container 'supr_app': " },
                { 10, "podman rm supr_app;" },
                { 11, "Remove pod 'Simple Pod' ('si_po'): " },
                { 12, "podman pod rm si_po;" },
            },
        },
        [s .. "03"] = {
            description = "Update simple pod. Names are mixed case and have spaces and there is no pod path.",
            parameters = { "update", "@nona" },
            expectations = {
                { 7, "Update pod 'Simple Pod' ('si_po') ..." },
                { 8, "Update container 'supr_app' ..." },
                { 9, "podman pull registry.io/alpine:latest;" },
            },
        },
        [s .. "04"] = {
            description = "Recreate simple pod. Names are mixed case and have spaces and there is no pod path.",
            parameters = { "recreate", "@nona" },
            expectations = {
                { 11, "Remove pod 'Simple Pod' ('si_po'): " },
                { 13, "Create pod 'Simple Pod' ('si_po'): " },
            },
        },
        [s .. "05"] = {
            description = "Test for publish.",
            parameters = { "create", "recipe_008_publish" },
            expectations = {
                { 8, "podman pod create --name publish --publish 8433:433 --publish 8080:80/TCP --publish 127.0.0.1::42 --publish 127.0.0.1:62:43/UDP --publish 600-500 --publish 83 --publish 124 --publish 12/UDP;" },
            },
        },
        [s .. "06"] = {
            description = "Test for options.",
            parameters = { "create", "recipe_010_pod_options" },
            expectations = {
                { 8, "podman pod create --name options --some thing --another thing;" },
            },
        },
    },
}
