return {
    name = "volumes",
    pod = {
        registry = "registry.io",
        path = "/my_pod_path",
    },
    containers = {
        {
            image = "name:latest",
            volumes = {
                { "",                "/container/dir/anonymous", "" },
                { "named_volume",    "/container/dir/named",     "ro" },
                { "/absolute/path",  "/container/dir/absolute",  "" },
                { "./relative/path", "/container/dir/relative",  "z" },
                { "relative/path2",  "/container/dir/relative2", "" },
            }
        }
    }
}
