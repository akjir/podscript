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
                { 7, "ERROR: No default registry in recipe 'recipe_009_no_registry' set or empty!" },
            },
        },
        [s .. "02"] = {
            description = "Simple container.",
            parameters = { "create", "recipe_011_simple_container" },
            expectations = {
                { 11, "podman run --name simple --pod simple_container simple.io/simple:latest;" },
            },
        },
        [s .. "03"] = {
            description = "Container options.",
            parameters = { "create", "recipe_012_container_options" },
            expectations = {
                { 11, "podman run --name snoitpo --pod copti --unknown thing --another unknown conop.io/simple:latest;" },
            },
        },
        [s .. "04"] = {
            description = "Container commands.",
            parameters = { "create", "recipe_013_container_commands" },
            expectations = {
                { 11, "podman run --name commandos-1 --pod commandos bel.io/squad:1998 O'Hara Hancock 2 Woolridge3 Brooklyn:4 Blackwood=5 Duchamp-6;" },
            },
        },
        [s .. "05"] = {
            description = "Registry per container.",
            parameters = { "create", "recipe_014_registry_per_container" },
            expectations = {
                { 11, "podman run --name registry_wars-1 --pod registry_wars bestRegEver.io/bestConEver:latest;" },
                { 13, "podman run --name registry_wars-2 --pod registry_wars regMasterRace.io/conMasterRace:latest;" },
            },
        },
        [s .. "06"] = {
            description = "Registry per container.",
            parameters = { "recreate", "recipe_015_container_order" },
            expectations = {
                { 9, "podman stop order-4;" },
                { 11, "podman rm order-4;" },
                { 13, "podman stop order-3;" },
                { 15, "podman rm order-3;" },
                { 17, "podman stop order-2;" },
                { 19, "podman rm order-2;" },
                { 21, "podman stop order-1;" },
                { 23, "podman rm order-1;" },
                { 29, "podman run --name order-1 --pod order obey.io/order:1;" },
                { 31, "podman run --name order-2 --pod order obey.io/order:2;" },
                { 33, "podman run --name order-3 --pod order obey.io/order:3;" },
                { 35, "podman run --name order-4 --pod order obey.io/order:4;" },
            },
        },
        [s .. "07"] = {
            description = "Update containers without names.",
            parameters = { "update", "recipe_015_container_order" },
            expectations = {
                { 9, "Update container 'order-1' ..." },
                { 10, "podman pull obey.io/order:1;" },
                { 11, "Update container 'order-2' ..." },
                { 12, "podman pull obey.io/order:2;" },
                { 13, "Update container 'order-3' ..." },
                { 14, "podman pull obey.io/order:3;" },
                { 15, "Update container 'order-4' ..." },
                { 16, "podman pull obey.io/order:4;" },
            },
        },
        [s .. "08"] = { -- Note: T00808 was missing in original? Let's keep 09 as is or rename? The user said sequential.
            description = "Test for absolute and relative container names (update).",
            parameters = { "update", "recipe_017_container_naming" },
            expectations = {
                { 9, "Update container 'absolute' ..." },
                { 11, "Update container 'con_name-relative' ..." },
            },
        },
        [s .. "09"] = {
            description = "Test for absolute and relative container names (create).",
            parameters = { "create", "recipe_017_container_naming" },
            expectations = {
                { 11, "podman run --name absolute --pod con_name registry.io/name:latest;" },
                { 13, "podman run --name con_name-relative --pod con_name registry.io/name:latest;" },
            },
        },
        [s .. "10"] = {
            description = "Test for absolute and relative container names (remove).",
            parameters = { "remove", "recipe_017_container_naming" },
            expectations = {
                { 9, "podman stop con_name-relative;" },
                { 11, "podman rm con_name-relative;" },
                { 13, "podman stop absolute;" },
                { 15, "podman rm absolute;" },
            },
        },
        [s .. "11"] = {
            description = "Test for correct parsing of volumes.",
            parameters = { "create", "recipe_018_container_volumes" },
            expectations = {
                { 10, "podman run --name volumes-1 --pod volumes --volume /container/dir/anonymous --volume /my_pod_path/named_volume:/container/dir/named:ro --volume /absolute/path:/container/dir/absolute --volume /my_pod_path/relative/path:/container/dir/relative:z --volume /my_pod_path/relative/path2:/container/dir/relative2 --volume /my_pod_path/relative/path3:/container/dir/relative3 registry.io/name:latest;" },
            },
        },
        [s .. "12"] = {
            description = "Test for correct parsing of volume with no indivudual pod path.",
            parameters = { "create", "recipe_019_container_volumes_with_no_path" },
            expectations = {
                { 11, "podman run --name volumes-1 --pod volumes --volume /pods/volumes/named_volume:/container/dir/named:ro --volume /absolute/path:/container/dir/absolute registry.io/name:latest;" },
            },
        },
        [s .. "13"] = {
            description = "Container with shell command.",
            parameters = { "create", "recipe_020_container_commands_2" },
            expectations = {
                { 11, "podman run --name cmd_con --pod cmd_test registry.io/alpine:latest sh -c echo 'hello world';" },
            },
        },
    },
}
