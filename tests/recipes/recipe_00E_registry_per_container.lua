return {
    name = "Registry Wars",
    pod = {
        registry = "bestRegEver.io",
    },
    containers = {
        {
            image = "bestConEver:latest",
        },
        {
            registry = "regMasterRace.io",
            image = "conMasterRace:latest",
        },
    },
}
