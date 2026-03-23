return {
    config_name = "test_psc",
    tests = {
        T00101 = {
            description = "Registry per container.",
            action = "create",
            target = "test_pc_registry",
            expectations = {
                { 5, "podman run --name pod-registry-super --pod pod-registry superpods.io/super_container:latest;" },
                { 6, "podman run --name pod-registry-mega --pod pod-registry megapods.io/mega_container:latest;" },
            },
        },
        T00102 = {
            description = "Commands for container.",
            action = "create",
            target = "test_pc_commands",
            expectations = {
                { 5, "podman run --name pod-commands-app --pod pod-commands podreg.io/comands:latest command1 command 2 command3;" },
            },
        },
    },
}
