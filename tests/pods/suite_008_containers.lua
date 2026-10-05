local s = "008"
return {
    -- Tests for containers.
    config = "config_008_containers",
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "No registy defined in recipe.",
            parameters = { "create", "recipe_009_no_registry" },
            expectations = {
                sequence = {
                    "ERROR: No default registry in recipe 'recipe_009_no_registry' set or empty!"
                }
            },
        },
        [s .. "02"] = {
            description = "Simple container.",
            parameters = { "create", "recipe_011_simple_container" },
            expectations = {
                sequence = {
                    "podman run --name simple --pod simple_container --detach simple.io/simple:latest"
                }
            },
        },
        [s .. "03"] = {
            description = "Container options.",
            parameters = { "create", "recipe_012_container_options" },
            expectations = {
                sequence = {
                    "podman run --name snoitpo --pod copti --unknown thing --another unknown conop.io/simple:latest"
                }
            },
        },
        [s .. "04"] = {
            description = "Container commands.",
            parameters = { "create", "recipe_013_container_commands" },
            expectations = {
                sequence = {
                    "podman run --name commandos-1 --pod commandos --detach bel.io/squad:1998 'O'\\''Hara' 'Hancock 2' Woolridge3 Brooklyn:4 Blackwood=5 Duchamp-6"
                }
            },
        },
        [s .. "05"] = {
            description = "Registry per container.",
            parameters = { "create", "recipe_014_registry_per_container" },
            expectations = {
                sequence = {
                    "podman run --name registry_wars-1 --pod registry_wars --detach bestRegEver.io/bestConEver:latest",
                    "podman run --name registry_wars-2 --pod registry_wars --detach regMasterRace.io/conMasterRace:latest"
                }
            },
        },
        [s .. "06"] = {
            description = "Registry per container.",
            parameters = { "recreate", "recipe_015_container_order" },
            expectations = {
                sequence = {
                    "podman stop order-4",
                    "podman rm order-4",
                    "podman stop order-3",
                    "podman rm order-3",
                    "podman stop order-2",
                    "podman rm order-2",
                    "podman stop order-1",
                    "podman rm order-1",
                    "podman run --name order-1 --pod order --detach obey.io/order:1",
                    "podman run --name order-2 --pod order --detach obey.io/order:2",
                    "podman run --name order-3 --pod order --detach obey.io/order:3",
                    "podman run --name order-4 --pod order --detach obey.io/order:4"
                }
            },
        },
        [s .. "07"] = {
            description = "Update containers without names.",
            parameters = { "update", "recipe_015_container_order" },
            expectations = {
                sequence = {
                    "Update container 'order-1' ...",
                    "podman pull obey.io/order:1",
                    "Update container 'order-2' ...",
                    "podman pull obey.io/order:2",
                    "Update container 'order-3' ...",
                    "podman pull obey.io/order:3",
                    "Update container 'order-4' ...",
                    "podman pull obey.io/order:4"
                }
            },
        },
        [s .. "08"] = { -- Note: T00808 was missing in original? Let's keep 09 as is or rename? The user said sequential.
            description = "Test for absolute and relative container names (update).",
            parameters = { "update", "recipe_017_container_naming" },
            expectations = {
                sequence = {
                    "Update container 'absolute' ...",
                    "Update container 'con_name-relative' ..."
                }
            },
        },
        [s .. "09"] = {
            description = "Test for absolute and relative container names (create).",
            parameters = { "create", "recipe_017_container_naming" },
            expectations = {
                sequence = {
                    "podman run --name absolute --pod con_name --detach registry.io/name:latest",
                    "podman run --name con_name-relative --pod con_name --detach registry.io/name:latest"
                }
            },
        },
        [s .. "10"] = {
            description = "Test for absolute and relative container names (remove).",
            parameters = { "remove", "recipe_017_container_naming" },
            expectations = {
                sequence = {
                    "podman stop con_name-relative",
                    "podman rm con_name-relative",
                    "podman stop absolute",
                    "podman rm absolute"
                }
            },
        },
        [s .. "11"] = {
            description = "Test for correct parsing of volumes.",
            parameters = { "create", "recipe_018_container_volumes" },
            expectations = {
                sequence = {
                    "podman run --name volumes-1 --pod volumes --detach --volume /container/dir/anonymous --volume /my_pod_path/named_volume:/container/dir/named:ro --volume /absolute/path:/container/dir/absolute --volume /my_pod_path/relative/path:/container/dir/relative:z --volume /my_pod_path/.relative/path2:/container/dir/relative2 --volume /my_pod_path/relative/path3:/container/dir/relative3 --volume /my_pod_path/.config:/container/dir/hidden1 --volume /my_pod_path/.config2:/container/dir/hidden2 registry.io/name:latest"
                }
            },
        },
        [s .. "12"] = {
            description = "Test for correct parsing of volume with no indivudual pod path.",
            parameters = { "create", "recipe_019_container_volumes_with_no_path" },
            expectations = {
                sequence = {
                    "podman run --name volumes-1 --pod volumes --detach --volume /pods/volumes/named_volume:/container/dir/named:ro --volume /absolute/path:/container/dir/absolute registry.io/name:latest"
                }
            },
        },
        [s .. "13"] = {
            description = "Container with shell command.",
            parameters = { "create", "recipe_020_container_commands_2" },
            expectations = {
                sequence = {
                    "podman run --name cmd_con --pod cmd_test --detach registry.io/alpine:latest sh -c 'echo '\\''hello world'\\'''"
                }
            },
        },
    },
}
