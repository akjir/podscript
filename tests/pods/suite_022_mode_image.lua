local s = "022"
return {
    -- Tests for image mode.
    suite = s,
    config = "config_001_default",
    tests = {
        [s .. "01"] = {
            description = "Print image help.",
            parameters = { "image", "help" },
            expectations = {
                sequence = {
                    "Usage: pods image [OPTIONS] ACTION",
                    "ACTIONS:",
                    "  prune              prune dangling or all unused images"
                }
            },
        },
        [s .. "02"] = {
            description = "Print image help on unknown action.",
            parameters = { "image", "unknown_action" },
            expectations = {
                sequence = {
                    "ERROR: Unknown action 'unknown_action' for image mode.",
                    "Usage: pods image [OPTIONS] ACTION"
                }
            },
        },
        [s .. "03"] = {
            description = "Simulate image prune (dangling).",
            simulate = true,
            parameters = { "image", "--force", "prune" },
            expectations = {
                sequence = {
                    "Prune images: ",
                    "podman image prune -f"
                }
            },
        },
        [s .. "04"] = {
            description = "Simulate image prune (all).",
            simulate = true,
            parameters = { "image", "--all", "--force", "prune" },
            expectations = {
                sequence = {
                    "Prune images: ",
                    "podman image prune -f -a"
                }
            },
        },
                [s .. "05"] = {
            description = "Test image prune preview with mock.",
            parameters = { "image", "--preview", "prune" },
            run = function()
                local old_exec_capture = system.exec_capture
                local captured_cmd = nil

                ---@diagnostic disable-next-line: duplicate-set-field
                system.exec_capture = function(cmd)
                    if string.find(cmd, "podman ps %-aq") then
                        return {}, true
                    else
                        captured_cmd = cmd
                        local lines = {
                            "abcd1234efgh;;;long1;;;my-repo;;;1.0;;;10.5 MB;;;2 weeks ago",
                            "ijkl5678mnop;;;long2;;;<none>;;;<none>;;;500 kB;;;3 weeks ago"
                        }
                        return lines, true
                    end
                end

                main({"image", "--preview", "prune", "--config=tests/pods/configs/config_001_default"})

                system.exec_capture = old_exec_capture

                return captured_cmd
            end,
            expected = "podman images --filter dangling=true --format \"{{.ID}};;;{{.Id}};;;{{.Repository}};;;{{.Tag}};;;{{.Size}};;;{{.Created}}\""
        },
        [s .. "06"] = {
            description = "Test image prune preview all with mock.",
            parameters = { "image", "--preview", "--all", "prune" },
            run = function()
                local old_exec_capture = system.exec_capture
                local captured_cmd = nil

                ---@diagnostic disable-next-line: duplicate-set-field
                system.exec_capture = function(cmd)
                    if string.find(cmd, "podman ps %-aq") then
                        return {}, true
                    else
                        captured_cmd = cmd
                        return {}, true
                    end
                end

                main({"image", "--preview", "--all", "prune", "--config=tests/pods/configs/config_001_default"})

                system.exec_capture = old_exec_capture

                return captured_cmd
            end,
            expected = "podman images --format \"{{.ID}};;;{{.Id}};;;{{.Repository}};;;{{.Tag}};;;{{.Size}};;;{{.Created}}\""
        },
        [s .. "07"] = {
            description = "Test image prune preview output formatting and exclusion logic.",
            parameters = { "image", "--preview", "prune" },
            run = function()
                local old_exec_capture = system.exec_capture

                ---@diagnostic disable-next-line: duplicate-set-field
                system.exec_capture = function(cmd)
                    if string.find(cmd, "podman ps %-aq") then
                        return {"c1"}, true
                    elseif string.find(cmd, "podman inspect") then
                        -- returns the long ID of the second image, meaning it is in use
                        return {"long2"}, true
                    else
                        local lines = {
                            "abcd1234efgh;;;long1;;;my-repo;;;1.0;;;10.5 MB;;;2 weeks ago",
                            "ijkl5678mnop;;;long2;;;<none>;;;<none>;;;500 kB;;;3 weeks ago"
                        }
                        return lines, true
                    end
                end

                main({"image", "--preview", "prune", "--config=tests/pods/configs/config_001_default"})

                system.exec_capture = old_exec_capture
                return true
            end,
            expected = true,
            expectations = {
                sequence = {
                    "Images to be pruned:",
                    "  - my-repo:1.0",
                    "---------------------------------------------------------------------------",
                    "Total space reclaimable:"
                },
                not_sequence = {
                    "  - ijkl5678mnop"
                }
            }
        }
    }
}
