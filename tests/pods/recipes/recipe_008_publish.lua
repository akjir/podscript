return {
    name = "publish",
    pod = {
        registry = "publisher.io",
        -- --publish [[ip:][hostPort]:]containerPort[/protocol]
        -- 127.0.0.1::80 valid, "container port is randomly assigned a port on the host"
        -- "Both hostPort and containerPort can be specified as a range of ports."
        publish = {
            { 8433,           433 },         -- "-p 8433:433"
            { 8080,           80,   "TCP" }, -- "-p 8080:80/TCP"
            { "127.0.0.1:",   42 },          -- "-p 127.0.0.1::42"
            { "127.0.0.1:62", 43,   "UDP" }, -- "-p 127.0.0.1:62:43/UDP"
            { "600-500" },                   -- "-p 600-500"
            { "",             83 },          -- "-p 83"
            { 124 },                         -- "-p 124"
            { 12,             "UDP" },       -- "-p 12/UDP"
        },
    },
    containers = {
        {
            name = "publish",
            image = "publish:latest",
        },
    },
}
