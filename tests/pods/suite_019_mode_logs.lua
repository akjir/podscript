local s = "019"
return {
    -- Tests for logs mode.
    suite = s,
    config = "config_015_commands",
    tests = {
        [s .. "01"] = {
            description = "Print logs help.",
            parameters = { "logs", "help" },
            expectations = {
                sequence = {
                    "Usage: pods logs [OPTIONS] [<action>] <recipe>[/container]"
                }
            },
        },
        [s .. "02"] = {
            description = "Simulate logs for recipe (implicitly show).",
            simulate = true,
            parameters = { "logs", "recipe_011_simple_container" },
            expectations = {
                sequence = {
                    "Execute log command: ",
                    "podman pod logs -n --color simple_container"
                }
            },
        },
        [s .. "03"] = {
            description = "Simulate logs with explicit show.",
            simulate = true,
            parameters = { "logs", "show", "recipe_011_simple_container" },
            expectations = {
                sequence = {
                    "Execute log command: ",
                    "podman pod logs -n --color simple_container"
                }
            },
        },
        [s .. "04"] = {
            description = "Simulate logs follow.",
            simulate = true,
            parameters = { "logs", "follow", "recipe_011_simple_container" },
            expectations = {
                sequence = {
                    "Execute log command: ",
                    "podman pod logs -n --color -f simple_container"
                }
            },
        },
        [s .. "05"] = {
            description = "Simulate logs with all options.",
            simulate = true,
            parameters = { "logs", "--tail=10", "--since=1h", "--until=2h", "--timestamps", "recipe_011_simple_container" },
            expectations = {
                sequence = {
                    "Execute log command: ",
                    "podman pod logs -n --color --since 1h --until 2h --tail 10 --timestamps simple_container"
                }
            },
        },
        [s .. "06"] = {
            description = "Simulate logs for specific container (index).",
            simulate = true,
            parameters = { "logs", "recipe_006_commands/1" },
            expectations = {
                sequence = {
                    "Execute log command: ",
                    "podman pod logs -n --color -c cmd_pod-1 cmd_pod"
                }
            },
        },
        [s .. "07"] = {
            description = "Simulate logs for specific container (relative).",
            simulate = true,
            parameters = { "logs", "recipe_006_commands/*db" },
            expectations = {
                sequence = {
                    "Execute log command: ",
                    "podman pod logs -n --color -c cmd_pod-db cmd_pod"
                }
            },
        },
        [s .. "08"] = {
            description = "Simulate logs for specific container (relative without asterisk).",
            simulate = true,
            parameters = { "logs", "recipe_006_commands/db" },
            expectations = {
                sequence = {
                    "Execute log command: ",
                    "podman pod logs -n --color -c cmd_pod-db cmd_pod"
                }
            },
        },
        [s .. "08b"] = {
            description = "Simulate logs for specific container (absolute).",
            simulate = true,
            parameters = { "logs", "recipe_006_commands/cmd_pod-db" },
            expectations = {
                sequence = {
                    "Execute log command: ",
                    "podman pod logs -n --color -c cmd_pod-db cmd_pod"
                }
            },
        },
        [s .. "09"] = {
            description = "Error when recipe not found.",
            simulate = true,
            parameters = { "logs", "missing_recipe" },
            expectations = {
                sequence = {
                    "ERROR: Recipe 'missing_recipe' could not be loaded."
                }
            },
        },
        [s .. "10"] = {
            description = "Error when container not found.",
            simulate = true,
            parameters = { "logs", "recipe_006_commands/missing" },
            expectations = {
                sequence = {
                    "ERROR: Container 'missing' not found in recipe 'recipe_006_commands'."
                }
            },
        },
        [s .. "11"] = {
            description = "Error with multiple targets.",
            simulate = true,
            parameters = { "logs", "show", "recipe_011_simple_container", "recipe_006_commands" },
            expectations = {
                sequence = {
                    "ERROR: Logs command only supports a single recipe target."
                }
            },
        },
        [s .. "12"] = {
            description = "Error with invalid action.",
            simulate = true,
            parameters = { "logs", "invalid_action", "recipe_011_simple_container" },
            expectations = {
                sequence = {
                    "ERROR: Invalid action 'invalid_action' or too many arguments."
                }
            },
        },
        [s .. "13"] = {
            description = "Mock execution in non-simulate mode.",
            parameters = { "logs", "recipe_011_simple_container" },
            run = function()
                local old_execute = os.execute
                local captured_cmd = nil
                ---@diagnostic disable-next-line: duplicate-set-field
                os.execute = function(cmd)
                    captured_cmd = cmd
                    return true, "exit", 0
                end

                main({"logs", "recipe_011_simple_container", "--config=tests/pods/configs/config_015_commands"})

                os.execute = old_execute

                if captured_cmd == "podman pod logs -n --color simple_container" then
                    return true
                end
                return captured_cmd
            end,
            expected = true
        },
        [s .. "14"] = {
            description = "Error when using group target explicitly.",
            simulate = true,
            parameters = { "logs", "show", "@all" },
            expectations = {
                sequence = {
                    "ERROR: Groups are not supported for logs. Only pods and containers are supported."
                }
            },
        },
        [s .. "15"] = {
            description = "Error when using group target implicitly.",
            simulate = true,
            parameters = { "logs", "@all" },
            expectations = {
                sequence = {
                    "ERROR: Groups are not supported for logs. Only pods and containers are supported."
                }
            },
        }
    }
}
