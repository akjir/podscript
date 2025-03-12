return {
    config_name = "test_psc",
    tests = {
        T00101 = {
            description = "Registry per container.",
            action = "create",
            target = "test_pc_registry",
            expectations = {
                {5, "podman run --name pod-registry-super --pod pod-registry superpods.io/super_container:latest;"},
                {6, "podman run --name pod-registry-mega --pod pod-registry megapods.io/mega_container:latest;"},
            },
        },
        T00102 = {
            description = "Commands for container.",
            action = "create",
            target = "test_pc_commands",
            expectations = {
                {5, "podman run --name pod-commands-app --pod pod-commands podreg.io/comands:latest command1 command 2 command3;"},
            },
        },
        T00103 = {
            description = "Target not defined in podscript config.",
            action = "create",
            target = "test_pc_none",
            expectations = {
                {3, "ERROR: PodConfig 'test_pc_none' not defined in config!"},
            },
        },
        T00104 = {
            description = "Publish argument support for pods.",
            action = "create",
            target = "test_pc_publish",
            expectations = {
                {4, "podman pod create --name pod-publish --publish 8433:433 --publish 8080:80/TCP --publish 127.0.0.1::42 --publish 127.0.0.1:62:43/UDP --publish 600-500 --publish 83 --publish 124 --publish 12/UDP;"},
            },
        },
    },
}
