# PodScript

A simple Lua script for managing Podman containers and pods using declarative recipe files.

## Disclaimer

This is a personal hobby project created for the primary purposes of learning Lua and exploring the use of AI-assisted development tools in a practical coding scenario. While a portion of the code has been generated with the assistance of an AI model, the majority of the code is human-written. The project is intended for private use.

## Features

*   Manage Podman pods and containers with simple commands ('create', 'recreate', 'remove', 'update').
*   Define pods and containers in declarative Lua recipe files.
*   Organize recipes into groups for managing multiple applications at once.
*   Flexible configuration through a configuration file.
*   Dry-run mode to preview commands before execution.

## Usage

```bash
lua pods.lua [OPTIONS] ACTION [TARGETS]
```

### Actions

*   'create': Create a new pod and its containers.
*   'recreate': Remove and then create a pod.
*   'remove': Remove a pod and its containers.
*   'update': Update the container images of a pod.

### Targets

*   '<recipe_name>': The name of a recipe file.
*   '@<group_name>': The name of a recipe group defined in a configuration file.

### Options

*   '--config <config_name>': Use a specific configuration file.
*   '--help': Display the help message.

## Configuration

Configuration is done in a specific file. This file allows you to define:

*   'dryrun': If 'true', commands will be printed but not executed.
*   'recipes': The path to your recipe files and groups of recipes.
*   'pods': The default path for pod data.

## Recipes

Recipes are Lua files that define a pod and its containers. A recipe file returns a table with the following structure:

```lua
return {
    name = "my-pod",
    pod = {
        name = "pod-my-pod",
        registry = "docker.io",
        -- ... pod options
    },
    containers = { "my-container" },
    container = {
        ["my-container"] = {
            image = "my-image:latest",
            -- ... container options
        },
    },
}
```

## Testing

To run the test suite, execute the following command:

```bash
lua test_suite.lua
```

## License

This project is licensed under the GNU General Public License v3.0. See the 'LICENSE' file for details.
