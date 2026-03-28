return {
    name = "volumes",
    pod = {
        registry = "registry.io",
    },
    containers = {
        {
            image = "name:latest",
            volumes = {
                { "named_volume",   "/container/dir/named",    "ro" },
                { "/absolute/path", "/container/dir/absolute", "" },
            }
        }
    }
}
