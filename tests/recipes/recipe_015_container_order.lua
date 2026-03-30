return {
    name = "Order",
    pod = {
        registry = "obey.io",
    },
    containers = {
        {
            image = "order:1",
        },
        {
            image = "order:2",
        },
        {
            image = "order:3",
        },
        {
            image = "order:4",
        },
    },
}
