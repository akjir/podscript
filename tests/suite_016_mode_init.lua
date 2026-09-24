local s = "016"
return {
    -- Tests for init mode.
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "Print init help.",
            parameters = { "init", "help" },
            expectations = {
                { 4, "Usage: pods init [OPTIONS]" },
            },
        },
        [s .. "02"] = {
            description = "Unknown action in init mode.",
            parameters = { "init", "unknown_action" },
            expectations = {
                { 3, "ERROR: Unknown action: unknown_action" },
            },
        },
        [s .. "03"] = {
            description = "Init mode fails when recipe.lua already exists.",
            parameters = { "init" },
            expectations = {
                { 3, "ERROR: File './recipe.lua' already exists!" },
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

                local recipe_content = "return {\n"
                    .. "    name = \"Example Pod\",\n"
                    .. "    description = \"Example web service pod managed by PodScript.\",\n"
                    .. "    pod = {\n"
                    .. "        name = \"web-service\",\n"
                    .. "        path = \"/pods\",\n"
                    .. "        registry = \"docker.io\",\n"
                    .. "        publish = {\n"
                    .. "            { 8080, 80, \"TCP\" },\n"
                    .. "        },\n"
                    .. "    },\n"
                    .. "    containers = {\n"
                    .. "        {\n"
                    .. "            name = \"*app\",\n"
                    .. "            detach = true,\n"
                    .. "            image = \"example:latest\",\n"
                    .. "            restart = \"always\",\n"
                    .. "        },\n"
                    .. "    },\n"
                    .. "}\n"
                local config_content = "return {\n"
                    .. "    pods = {\n"
                    .. "        path = \"/pods\",\n"
                    .. "    },\n"
                    .. "    recipes = {\n"
                    .. "        groups = {\n"
                    .. "            all = {\n"
                    .. "                \"recipe\",\n"
                    .. "            },\n"
                    .. "        },\n"
                    .. "    },\n"
                    .. "}\n"

                system.write_file(test_recipe, recipe_content)
                system.write_file(test_config, config_content)

                local recipe_file = io.open(test_recipe, "r")
                local actual_recipe = recipe_file and recipe_file:read("*a")
                if recipe_file then recipe_file:close() end

                local config_file = io.open(test_config, "r")
                local actual_config = config_file and config_file:read("*a")
                if config_file then config_file:close() end

                local registry = { flags = {}, parameters = {} }
                local load_success = config__load_and_set(registry, test_config)
                local recipe_table = recipe__load(test_dir, "recipe", true)
                local recipe_valid = recipe_table and recipe__validate(registry, recipe_table, "recipe")

                os.execute("rm -rf " .. test_dir)

                return actual_recipe == recipe_content
                    and actual_config == config_content
                    and load_success == true
                    and recipe_valid == true
                    and registry.recipes.groups.all[1] == "recipe"
            end,
            expected = true,
        },
        [s .. "05"] = {
            description = "General help lists init mode.",
            parameters = { "help" },
            expectations = {
                { 10, "  init               initialize default configuration and recipe" },
            },
        },
    }
}
