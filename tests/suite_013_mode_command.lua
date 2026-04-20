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
                { 6, "WARNING: Command 'missing_container' has no description." },
                { 7, "WARNING: Command 'missing_execute' has no description." },
                { 8, "WARNING: Command 'run_absolute' has no description." },
                { 9, "WARNING: Command 'run_int_container' has no description." },
                { 10, "WARNING: Command 'run_int_container_2' has no description." },
                { 11, "WARNING: Command 'run_int_user' has no description." },
                { 12, "Commands for recipe 'recipe_006_commands':" },
                { 13, "  add_index: Adds missing database indices." },
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
            description = "Simulate command integer container (index 1).",
            simulate = true,
            parameters = { "command", "recipe_006_commands", "run_int_container" },
            expectations = {
                { 7, "Execute command 'script.sh run-int-container' in container 'cmd_pod-1': " },
                { 8, "podman exec -it cmd_pod-1 script.sh run-int-container;" },
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
        [s .. "10"] = {
            description = "Simulate command integer container (index 2, named *db).",
            simulate = true,
            parameters = { "command", "recipe_006_commands", "run_int_container_2" },
            expectations = {
                { 7, "Execute command 'script.sh run-int-container-2' in container 'cmd_pod-db': " },
                { 8, "podman exec -it cmd_pod-db script.sh run-int-container-2;" },
            },
        },
        [s .. "11"] = {
            description = "Print command list for recipe without commands.",
            parameters = { "command", "recipe_011_simple_container", "list" },
            expectations = {
                { 6, "INFO: No pod path in recipe 'recipe_011_simple_container' set. Path '/tmp/simple_container' used." },
                { 7, "There are no commands defined in recipe 'recipe_011_simple_container'." },
            },
        },
        [s .. "12"] = {
            description = "Print command list for recipe with only invalid commands.",
            parameters = { "command", "recipe_021_no_description_commands", "list" },
            expectations = {
                { 6, "WARNING: Command 'cmd1' has no description." },
                { 7, "WARNING: Command 'cmd2' has no description." },
                { 8, "There is no valid command in recipe 'recipe_021_no_description_commands'." },
            },
        },
    }
}
