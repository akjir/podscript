local s = "020"
return {
    -- Tests for connect mode.
    suite = s,
    config = "config_015_commands",
    tests = {
        [s .. "01"] = {
            description = "Print connect help.",
            parameters = { "connect", "help" },
            expectations = {
                sequence = {
                    "Usage: pods connect [OPTIONS] [<action>] <target>"
                }
            },
        },
        [s .. "02"] = {
            description = "Simulate connect for a recipe with 1 container (implicitly shell).",
            simulate = true,
            parameters = { "connect", "recipe_011_simple_container" },
            expectations = {
                sequence = {
                    "Execute connect command: ",
                    "podman exec -it simple sh -c 'command -v bash >/dev/null 2>&1 && exec bash || exec sh'"
                }
            },
        },
        [s .. "03"] = {
            description = "Simulate connect with explicit shell action.",
            simulate = true,
            parameters = { "connect", "shell", "recipe_011_simple_container" },
            expectations = {
                sequence = {
                    "Execute connect command: ",
                    "podman exec -it simple sh -c 'command -v bash >/dev/null 2>&1 && exec bash || exec sh'"
                }
            },
        },
        [s .. "04"] = {
            description = "Simulate connect for specific container (index).",
            simulate = true,
            parameters = { "connect", "recipe_006_commands/1" },
            expectations = {
                sequence = {
                    "Execute connect command: ",
                    "podman exec -it cmd_pod-1 sh -c 'command -v bash >/dev/null 2>&1 && exec bash || exec sh'"
                }
            },
        },
        [s .. "05"] = {
            description = "Simulate connect for specific container (relative).",
            simulate = true,
            parameters = { "connect", "recipe_006_commands/db" },
            expectations = {
                sequence = {
                    "Execute connect command: ",
                    "podman exec -it cmd_pod-db sh -c 'command -v bash >/dev/null 2>&1 && exec bash || exec sh'"
                }
            },
        },
        [s .. "06"] = {
            description = "Simulate connect directly to an absolute container name.",
            simulate = true,
            parameters = { "connect", "my_absolute_container" },
            expectations = {
                sequence = {
                    "Execute connect command: ",
                    "podman exec -it my_absolute_container sh -c 'command -v bash >/dev/null 2>&1 && exec bash || exec sh'"
                },
                not_contains = {
                    "cannot open",
                    "Couldn't load recipe"
                }
            },
        },
        [s .. "07"] = {
            description = "Error when recipe has multiple containers and none specified.",
            simulate = true,
            parameters = { "connect", "recipe_006_commands" },
            expectations = {
                sequence = {
                    "ERROR: Recipe 'recipe_006_commands' has multiple containers. Please specify one explicitly."
                }
            },
        },
        [s .. "08"] = {
            description = "Error when specific container not found.",
            simulate = true,
            parameters = { "connect", "recipe_006_commands/missing" },
            expectations = {
                sequence = {
                    "ERROR: Container 'missing' not found in recipe 'recipe_006_commands'."
                }
            },
        },
        [s .. "09"] = {
            description = "Error with multiple targets.",
            simulate = true,
            parameters = { "connect", "shell", "recipe_011_simple_container", "another_target" },
            expectations = {
                sequence = {
                    "ERROR: Connect command only supports a single target."
                }
            },
        },
        [s .. "10"] = {
            description = "Error with invalid action.",
            simulate = true,
            parameters = { "connect", "invalid_action", "recipe_011_simple_container" },
            expectations = {
                sequence = {
                    "ERROR: Invalid action 'invalid_action' or too many arguments."
                }
            },
        },
        [s .. "11"] = {
            description = "Mock execution in non-simulate mode (container exists).",
            parameters = { "connect", "recipe_011_simple_container" },
            run = function()
                local old_execute = os.execute
                local old_exec_capture = system.exec_capture
                local captured_cmd = nil

                system.exec_capture = function(cmd)
                    if string.match(cmd, "podman container inspect") then
                        return {"running"}
                    end
                    return {}
                end

                ---@diagnostic disable-next-line: duplicate-set-field
                os.execute = function(cmd)
                    captured_cmd = cmd
                    return true, "exit", 0
                end

                main({"connect", "recipe_011_simple_container", "--config=tests/pods/configs/config_015_commands"})

                os.execute = old_execute
                system.exec_capture = old_exec_capture

                if captured_cmd == "podman exec -it simple sh -c 'command -v bash >/dev/null 2>&1 && exec bash || exec sh'" then
                    return true
                end
                return captured_cmd
            end,
            expected = true
        },
        [s .. "12"] = {
            description = "Mock execution fails if container is not running.",
            parameters = { "connect", "recipe_011_simple_container" },
            run = function()
                local old_execute = os.execute
                local old_exec_capture = system.exec_capture
                local captured_cmd = nil

                system.exec_capture = function(cmd)
                    if string.match(cmd, "podman container inspect") then
                        return {"exited"}
                    end
                    return {}
                end

                ---@diagnostic disable-next-line: duplicate-set-field
                os.execute = function(cmd)
                    captured_cmd = cmd
                    return true, "exit", 0
                end

                main({"connect", "recipe_011_simple_container", "--config=tests/pods/configs/config_015_commands"})

                os.execute = old_execute
                system.exec_capture = old_exec_capture

                return captured_cmd == nil
            end,
            expected = true
        },
        [s .. "13"] = {
            description = "Error when using group target explicitly.",
            simulate = true,
            parameters = { "connect", "shell", "@all" },
            expectations = {
                sequence = {
                    "ERROR: Groups are not supported for connect. Please specify a single target."
                }
            },
        },
        [s .. "14"] = {
            description = "Error when using group target implicitly.",
            simulate = true,
            parameters = { "connect", "@all" },
            expectations = {
                sequence = {
                    "ERROR: Groups are not supported for connect. Please specify a single target."
                }
            },
        },
        [s .. "15"] = {
            description = "Error when missing target is not a recipe and not a running container.",
            parameters = { "connect", "missing_target" },
            expectations = {
                sequence = {
                    "ERROR: Target 'missing_target' does not exist."
                },
                not_contains = {
                    "cannot open",
                    "Couldn't load recipe",
                    "is not running or does not exist"
                }
            }
        }
    }
}
