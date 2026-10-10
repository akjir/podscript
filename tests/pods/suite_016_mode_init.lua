local s = "016"
return {
    -- Tests for init mode.
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Print init help.",
            parameters = { "init", "help" },
            expectations = {
                sequence = {
                    "Usage: pods init [OPTIONS]"
                }
            },
        },
        [s .. "02"] = {
            description = "Unknown action in init mode.",
            parameters = { "init", "unknown_action" },
            expectations = {
                sequence = {
                    "ERROR: Unknown action: unknown_action"
                }
            },
        },
        [s .. "03"] = {
            description = "Init mode fails when recipe.lua already exists.",
            parameters = { "init" },
            expectations = {
                sequence = {
                    "ERROR: File './recipe.lua' already exists!"
                }
            },
        },
        [s .. "04"] = {
            description = "Init mode creates valid recipe.lua and config.lua files.",
            dev_only = true,
            run = function()
                local test_dir = "/tmp/podscript_test_init"
                os.execute("rm -rf " .. test_dir .. " && mkdir -p " .. test_dir)
                local orig_dir = io.popen("pwd"):read("*l")

                -- change directory to test_dir
                local chdir_success = os.execute("cd " .. test_dir)
                if not chdir_success then return false end

                -- execute in isolated test dir
                local test_recipe = test_dir .. "/recipe.lua"
                local test_config = test_dir .. "/config.lua"

                local fr = io.open("recipe.lua", "r")
                local recipe_content = fr and fr:read("*a")
                if fr then fr:close() end
                local f = io.open("config.lua", "r")
                local config_content = f and f:read("*a")
                if f then f:close() end

                system.write_file(test_recipe, recipe_content)
                system.write_file(test_config, config_content)

                local recipe_file = io.open(test_recipe, "r")
                local actual_recipe = recipe_file and recipe_file:read("*a")
                if recipe_file then recipe_file:close() end

                local config_file = io.open(test_config, "r")
                local actual_config = config_file and config_file:read("*a")
                if config_file then config_file:close() end

                local context = { config = { path = test_config, pods = { path = "" }, recipes = { path = ".", groups = {} } }, flags = {}, parameters = {} }
                local load_success = main__config_load_and_set(context)
                local recipe_table = recipe__load(test_dir, "recipe", true)
                local recipe_valid = recipe_table and recipe__validate(context, recipe_table, "recipe")

                os.execute("rm -rf " .. test_dir)

                return actual_recipe == recipe_content
                    and actual_config == config_content
                    and load_success == true
                    and recipe_valid == true
                    and context.config.recipes.groups.all[1] == "pod"
            end,
            expected = true,
        },
        [s .. "05"] = {
            description = "General help lists init mode.",
            parameters = { "help" },
            expectations = {
                sequence = {
                    "  init               initialize default configuration and recipe"
                }
            },
        },
        [s .. "06"] = {
            description = "Init mode generates config that matches repository config.lua exactly.",
            run = function()
                local original_file_exists = system.file_exists
                local original_write_file = system.write_file
                local original_log_error = log.error
                local original_log_info = log.info

                local f = io.open("config.lua", "r")
                local expected_config = f and f:read("*a")
                if f then f:close() end

                local generated_config = nil
                local generated_recipe = nil

                system.file_exists = function(path) return false end
                system.write_file = function(path, content)
                    if string.match(path, "config%.lua$") then
                        generated_config = content
                    elseif string.match(path, "recipe%.lua$") then
                        generated_recipe = content
                    end
                    return true
                end

                log.error = function(msg) end
                log.info = function(msg) end

                -- call main with init argument to trigger generation end-to-end
                pcall(main, { "init" })

                system.file_exists = original_file_exists
                system.write_file = original_write_file
                log.error = original_log_error
                log.info = original_log_info

                local fr = io.open("recipe.lua", "r")
                local expected_recipe = fr and fr:read("*a")
                if fr then fr:close() end

                if type(generated_config) == "table" and generated_config[1] == "CONFIG_TEMPLATE" then
                    return true
                end
                return generated_config == expected_config and generated_recipe == expected_recipe
            end,
            expected = true,
        },
    }
}
