return {
    default_config = "config_001",
    tests = {
        T00101 = {
            description = "Print Help",
            config = "",
            action = "create",
            targets = {"target"},
            expectations = {
                {5, "podman run --name pod-registry-super --pod pod-registry superpods.io/super_container:latest;"},
                {6, "podman run --name pod-registry-mega --pod pod-registry megapods.io/mega_container:latest;"},
            },
        },
    }
}