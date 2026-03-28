return {
    -- Tests for containers.
    config = "config_008_containers",
    tests = {
        T00801 = {
            description = "No registy defined in recipe.",
            action = "create",
            targets = { "recipe_009_no_registry" },
            expectations = {
                { 5, "ERROR: No default registry in recipe 'recipe_009_no_registry' set or empty!" },
            },
        },
        T00802 = {
            description = "Simple container.",
            action = "create",
            targets = { "recipe_00B_simple_container" },
            expectations = {
                { 9, "podman run --name simple --pod simple_container simple.io/simple:latest;" },
            },
        },
        T00803 = {
            description = "Container options.",
            action = "create",
            targets = { "recipe_00C_container_options" },
            expectations = {
                { 9, "podman run --name snoitpo --pod copti --unknown thing --another unknown conop.io/simple:latest;" },
            },
        },
        T00804 = {
            description = "Container commands.",
            action = "create",
            targets = { "recipe_00D_container_commands" },
            expectations = {
                { 9, "podman run --name commandos-1 --pod commandos bel.io/squad:1998 O'Hara Hancock 2 Woolridge3 Brooklyn:4 Blackwood=5 Duchamp-6;" },
            },
        },
        T00805 = {
            description = "Registry per container.",
            action = "create",
            targets = { "recipe_00E_registry_per_container" },
            expectations = {
                { 9,  "podman run --name registry_wars-1 --pod registry_wars bestRegEver.io/bestConEver:latest;" },
                { 11, "podman run --name registry_wars-2 --pod registry_wars regMasterRace.io/conMasterRace:latest;" },
            },
        },
        T00806 = {
            description = "Registry per container.",
            action = "recreate",
            targets = { "recipe_00F_container_order" },
            expectations = {
                { 7,  "podman stop order-4;" },
                { 9,  "podman rm order-4;" },
                { 11, "podman stop order-3;" },
                { 13, "podman rm order-3;" },
                { 15, "podman stop order-2;" },
                { 17, "podman rm order-2;" },
                { 19, "podman stop order-1;" },
                { 21, "podman rm order-1;" },
                { 27, "podman run --name order-1 --pod order obey.io/order:1;" },
                { 29, "podman run --name order-2 --pod order obey.io/order:2;" },
                { 31, "podman run --name order-3 --pod order obey.io/order:3;" },
                { 33, "podman run --name order-4 --pod order obey.io/order:4;" },
            },
        },
        T00807 = {
            description = "Update containers without names.",
            action = "update",
            targets = { "recipe_00F_container_order" },
            expectations = {
                { 7,  "Update container 'order-1' ..." },
                { 8,  "podman pull obey.io/order:1;" },
                { 9,  "Update container 'order-2' ..." },
                { 10, "podman pull obey.io/order:2;" },
                { 11, "Update container 'order-3' ..." },
                { 12, "podman pull obey.io/order:3;" },
                { 13, "Update container 'order-4' ..." },
                { 14, "podman pull obey.io/order:4;" },
            },
        },
        T00809 = {
            description = "Test for absolute and relative container names (update).",
            action = "update",
            targets = { "recipe_011_container_naming" },
            expectations = {
                { 7, "Update container 'absolute' ..." },
                { 9, "Update container 'con_name-relative' ..." },
            },
        },
        T0080A = {
            description = "Test for absolute and relative container names (create).",
            action = "create",
            targets = { "recipe_011_container_naming" },
            expectations = {
                { 9,  "podman run --name absolute --pod con_name registry.io/name:latest;" },
                { 11, "podman run --name con_name-relative --pod con_name registry.io/name:latest;" },
            },
        },
        T0080B = {
            description = "Test for absolute and relative container names (remove).",
            action = "remove",
            targets = { "recipe_011_container_naming" },
            expectations = {
                { 7,  "podman stop con_name-relative;" },
                { 9,  "podman rm con_name-relative;" },
                { 11, "podman stop absolute;" },
                { 13, "podman rm absolute;" },
            },
        },
        T0080C = {
            description = "Test for correct parsing of volumes according to podman specs.",
            action = "create",
            targets = { "recipe_012_container_volumes" },
            expectations = {
                { 8, "podman run --name volumes-1 --pod volumes --volume /container/dir/anonymous --volume /my_pod_path/named_volume:/container/dir/named:ro --volume /absolute/path:/container/dir/absolute --volume /my_pod_path/relative/path:/container/dir/relative:z --volume /my_pod_path/relative/path2:/container/dir/relative2 registry.io/name:latest;" },
            },
        },
    },
}
