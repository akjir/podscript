local s = "013"
return {
    -- Tests for command mode.
    suite = s,
    config = "config_015_commands",
    tests = {
        [s .. "01"] = {
            description = "Print command help.",
            parameters = { "command", "help" },
            expectations = {
                { 6, "Usage: pods command [OPTIONS] NAME COMMAND" },
            },
        },
        [s .. "02"] = {
            description = "Print command list.",
            parameters = { "command", "recipe_006_commands", "list" },
            expectations = {
                { 6, "Commands for recipe 'recipe_006_commands':" },
            },
        },
        [s .. "03"] = {
            description = "Simulate command relative container name.",
            simulate = true,
            parameters = { "command", "recipe_006_commands", "add_index" },
            expectations = {
                { 7, "Execute command 'script.sh add-missing-indices' in container 'cmd_pod-db': " },
                { 8, "podman exec -it -u 33 cmd_pod-db script.sh add-missing-indices;" },
            },
        },
        [s .. "04"] = {
            description = "Simulate command absolute container name.",
            simulate = true,
            parameters = { "command", "recipe_006_commands", "run_absolute" },
            expectations = {
                { 7, "Execute command 'script.sh run-absolute' in container 'absolute_db': " },
                { 8, "podman exec -it absolute_db script.sh run-absolute;" },
            },
        },
        [s .. "05"] = {
            description = "Simulate command integer user.",
            simulate = true,
            parameters = { "command", "recipe_006_commands", "run_int_user" },
            expectations = {
                { 7, "Execute command 'script.sh run-int-user' in container 'absolute_db': " },
                { 8, "podman exec -it -u 1000 absolute_db script.sh run-int-user;" },
            },
        },
        [s .. "06"] = {
            description = "Simulate command integer container.",
            simulate = true,
            parameters = { "command", "recipe_006_commands", "run_int_container" },
            expectations = {
                { 7, "Execute command 'script.sh run-int-container' in container '1': " },
                { 8, "podman exec -it 1 script.sh run-int-container;" },
            },
        },
        [s .. "07"] = {
            description = "Command with missing container.",
            simulate = true,
            parameters = { "command", "recipe_006_commands", "missing_container" },
            expectations = {
                { 7, "ERROR: No container in command table set!" },
            },
        },
        [s .. "08"] = {
            description = "Command with missing execute.",
            simulate = true,
            parameters = { "command", "recipe_006_commands", "missing_execute" },
            expectations = {
                { 7, "ERROR: No command in command table set!" },
            },
        },
        [s .. "09"] = {
            description = "Unknown command.",
            simulate = true,
            parameters = { "command", "recipe_006_commands", "unknown" },
            expectations = {
                { 7, "ERROR: Command 'unknown' not found in recipe 'recipe_006_commands'." },
            },
        },
    }
}
