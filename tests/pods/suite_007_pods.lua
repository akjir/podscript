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
                sequence = {
                    "DEBUG: Debug mode is enabled.",
                    "DEBUG: Config './tests/pods/configs/config_007_pods.lua' is used.",
                    "INFO: Simulate mode is active.",
                    "DEBUG: Targets   - @nona",
                    "DEBUG: Untangled - recipe_007_simple_pod_no_name_and_path",
                    "Create pod 'Simple Pod' ('si_po'): ",
                    "podman pod create --name si_po",
                    "Create container 'supr_app': ",
                    "podman run --name supr_app --pod si_po --detach --restart never --volume /pods/si_po/config:/config:Z registry.io/alpine:latest"
                }
            },
        },
        [s .. "02"] = {
            description = "Remove simple pod. Names are mixed case and have spaces and there is no pod path.",
            parameters = { "remove", "@nona" },
            expectations = {
                sequence = {
                    "Stop container 'supr_app': ",
                    "podman stop supr_app",
                    "Remove container 'supr_app': ",
                    "podman rm supr_app",
                    "Remove pod 'Simple Pod' ('si_po'): ",
                    "podman pod rm si_po"
                }
            },
        },
        [s .. "03"] = {
            description = "Update simple pod. Names are mixed case and have spaces and there is no pod path.",
            parameters = { "update", "@nona" },
            expectations = {
                sequence = {
                    "Update pod 'Simple Pod' ('si_po') ...",
                    "Update container 'supr_app' ...",
                    "podman pull registry.io/alpine:latest"
                }
            },
        },
        [s .. "04"] = {
            description = "Recreate simple pod. Names are mixed case and have spaces and there is no pod path.",
            parameters = { "recreate", "@nona" },
            expectations = {
                sequence = {
                    "Remove pod 'Simple Pod' ('si_po'): ",
                    "Create pod 'Simple Pod' ('si_po'): "
                }
            },
        },
        [s .. "05"] = {
            description = "Test for publish.",
            parameters = { "create", "recipe_008_publish" },
            expectations = {
                sequence = {
                    "podman pod create --name publish --publish 8433:433 --publish 8080:80/TCP --publish 127.0.0.1::42 --publish 127.0.0.1:62:43/UDP --publish 600-500 --publish 83 --publish 124 --publish 12/UDP"
                }
            },
        },
        [s .. "06"] = {
            description = "Test for options.",
            parameters = { "create", "recipe_010_pod_options" },
            expectations = {
                sequence = {
                    "podman pod create --name options --network slirp4netns:port_handler=slirp4netns --some thing --another thing"
                }
            },
        },
        [s .. "07"] = {
            description = "Simulate create with config simulate = false.",
            config = "config_010_simulate_false_with_pods",
            parameters = { "create", "@nona" },
            simulate = true,
            expectations = {
                sequence = {
                    "INFO: Simulate mode is active.",
                    "podman pod create --name si_po",
                }
            },
        },
    },
}
