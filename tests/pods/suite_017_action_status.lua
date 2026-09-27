local s = "017"
return {
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Status of explicitly targeted running container.",
            dev_only = true,
            run = function()
                local original_exec = system.exec_capture
                system.exec_capture = function(cmd)
                    if string.find(cmd, "podman ps") then
                        return {
                            "cid1;;;simple.io/simple:latest;;;;;;2026-09-25;;;Up 2 days;;;80/tcp;;;simple;;;simple_container;;;0",
                            "cid2;;;registry.io/name:latest;;;;;;2026-09-26;;;Exited (1);;;;;;con_name-relative;;;con_name;;;1",
                            "cid3;;;unmanaged:latest;;;sh;;;2026-09-24;;;Up 3 days;;;;;;unmanaged;;;unmanaged-pod;;;0"
                        }
                    end
                    return original_exec(cmd)
                end
                main({ "--config=tests/pods/configs/config_008_containers", "status", "recipe_011_simple_container" })
                system.exec_capture = original_exec
            end,
            expectations = {
                sequence = {
                    "ID     POD                NAMES    STATUS      RESTARTS   CREATED   ",
                    "cid1   simple_container   simple   Up 2 days   0          2026-09-25"
                }
            },
        },
        [s .. "02"] = {
            description = "Status of full explicitly targeted running container.",
            dev_only = true,
            run = function()
                local original_exec = system.exec_capture
                system.exec_capture = function(cmd)
                    return {
                        "cid1;;;simple.io/simple:latest;;;;;;2026-09-25;;;Up 2 days;;;80/tcp;;;simple;;;simple_container;;;0" }
                end
                main({ "--config=tests/pods/configs/config_008_containers", "status", "--full",
                    "recipe_011_simple_container" })
                system.exec_capture = original_exec
            end,
            expectations = {
                sequence = {
                    "ID     POD                NAMES    STATUS      RESTARTS   CREATED      IMAGE                     COMMAND   PORTS ",
                    "cid1   simple_container   simple   Up 2 days   0          2026-09-25   simple.io/simple:latest             80/tcp"
                }
            },
        },
        [s .. "03"] = {
            description = "Status missing explicitly targeted running container.",
            dev_only = true,
            run = function()
                local original_exec = system.exec_capture
                system.exec_capture = function(cmd)
                    return {
                        "cid2;;;registry.io/name:latest;;;;;;2026-09-26;;;Exited (1);;;;;;con_name-relative;;;con_name;;;1" }
                end
                main({ "--config=tests/pods/configs/config_008_containers", "status", "recipe_017_container_naming" })
                system.exec_capture = original_exec
            end,
            expectations = {
                sequence = {
                    "ID     POD        NAMES               STATUS       RESTARTS   CREATED   ",
                    "-      con_name   absolute            Not Found    -          -         ",
                    "cid2   con_name   con_name-relative   Exited (1)   1          2026-09-26"
                }
            },
        },
        [s .. "04"] = {
            description = "Status all flag shows unmanaged too.",
            dev_only = true,
            run = function()
                local original_exec = system.exec_capture
                system.exec_capture = function(cmd)
                    return {
                        "cid1;;;simple.io/simple:latest;;;;;;2026-09-25;;;Up 2 days;;;80/tcp;;;simple;;;simple_container;;;0",
                        "cid2;;;registry.io/name:latest;;;;;;2026-09-26;;;Exited (1);;;;;;con_name-relative;;;con_name;;;1",
                        "cid3;;;unmanaged:latest;;;sh;;;2026-09-24;;;Up 3 days;;;;;;unmanaged;;;unmanaged-pod;;;0"
                    }
                end
                main({ "--config=tests/pods/configs/config_008_containers", "status", "--all" })
                system.exec_capture = original_exec
            end,
            expectations = {
                sequence = {
                    "ID     POD                NAMES               STATUS       RESTARTS   CREATED   ",
                    "cid2   con_name           con_name-relative   Exited (1)   1          2026-09-26",
                    "cid1   simple_container   simple              Up 2 days    0          2026-09-25",
                    "cid3   unmanaged-pod      unmanaged           Up 3 days    0          2026-09-24"
                }
            },
        }
    }
}
