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
                { 8, "podman run --name simple --pod pod-simple_container simple.io/simple:latest;" },
            },
        },
        T00803 = {
            description = "Container options.",
            action = "create",
            targets = { "recipe_00C_container_options" },
            expectations = {
                { 8, "podman run --name snoitop --pod pod-copti --unknown thing --another unknown conop.io/simple:latest;" },
            },
        },
        T00804 = {
            description = "Container commands.",
            action = "create",
            targets = { "recipe_00D_container_commands" },
            expectations = {
                { 8, "podman run --name pod-commandos-1 --pod pod-commandos bel.io/squad:1998 O'Hara Hancock 2 Woolridge3 Brooklyn:4 Blackwood=5 Duchamp-6;" },
            },
        },
        T00805 = {
            description = "Registry per container.",
            action = "create",
            targets = { "recipe_00E_registry_per_container" },
            expectations = {
                { 8, "podman run --name pod-registry_wars-1 --pod pod-registry_wars bestRegEver.io/bestConEver:latest;" },
                { 9, "podman run --name pod-registry_wars-2 --pod pod-registry_wars regMasterRace.io/conMasterRace:latest;" },
            },
        },
        T00806 = {
            description = "Registry per container.",
            action = "recreate",
            targets = { "recipe_00F_container_order" },
            expectations = {
                { 7,  "podman stop pod-order-4;" },
                { 8,  "podman rm pod-order-4;" },
                { 9,  "podman stop pod-order-3;" },
                { 10, "podman rm pod-order-3;" },
                { 11, "podman stop pod-order-2;" },
                { 12, "podman rm pod-order-2;" },
                { 13, "podman stop pod-order-1;" },
                { 14, "podman rm pod-order-1;" },
                { 18, "podman run --name pod-order-1 --pod pod-order obey.io/order:1;" },
                { 19, "podman run --name pod-order-2 --pod pod-order obey.io/order:2;" },
                { 20, "podman run --name pod-order-3 --pod pod-order obey.io/order:3;" },
                { 21, "podman run --name pod-order-4 --pod pod-order obey.io/order:4;" },
            },
        },
        T00807 = {
            description = "Update containers without names.",
            action = "update",
            targets = { "recipe_00F_container_order" },
            expectations = {
                { 7,  "Update container 'pod-order-1' ..." },
                { 8,  "podman pull obey.io/order:1;" },
                { 9,  "Update container 'pod-order-2' ..." },
                { 10, "podman pull obey.io/order:2;" },
                { 11, "Update container 'pod-order-3' ..." },
                { 12, "podman pull obey.io/order:3;" },
                { 13, "Update container 'pod-order-4' ..." },
                { 14, "podman pull obey.io/order:4;" },
            },
        },
        T00809 = {
            description = "Test for absolute and relative container names (update).",
            action = "update",
            targets = { "recipe_011_container_naming" },
            expectations = {
                { 7, "Update container 'absolute' ..." },
                { 9, "Update container 'pod-con_name-relative' ..." },
            },
        },
        T0080A = {
            description = "Test for absolute and relative container names (create).",
            action = "create",
            targets = { "recipe_011_container_naming" },
            expectations = {
                { 8, "podman run --name absolute --pod pod-con_name registry.io/name:latest;" },
                { 9, "podman run --name pod-con_name-relative --pod pod-con_name registry.io/name:latest;" },
            },
        },
    },
}
