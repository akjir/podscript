# PodScript

A simple Lua script for managing Podman containers and pods using declarative recipe files.

## Disclaimer

This is a personal hobby project created for the primary purposes of learning Lua and exploring the use of AI-assisted development tools in a practical coding scenario. While a portion of the code has been generated with the assistance of an AI model, the majority of the code is human-written. The project is intended for private use.

**WARNING:** This software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

**IMPORTANT:** Use this script at your own risk. It is strongly recommended to maintain current backups of your data and container configurations before using this script. The author is not responsible for any data loss, corruption, or system instability.

## Features

*   Manage Podman pods and containers with simple commands (`create`, `recreate`, `remove`, `update`).
*   Define pods and containers in declarative Lua recipe files.
*   Configure container specifics individually like registries, publish ports, lifecycle options, volumes, restart policies, and custom launch commands.
*   Organize recipes into groups for managing multiple applications at once.
*   Flexible configuration through a configuration file.
*   Simulate mode to preview commands before execution.

## Usage

```bash
lua pods.lua [OPTIONS] ACTION [TARGETS]
```
### Actions

*   `create`: Create a new pod and its containers.
*   `recreate`: Remove and then create a pod.
*   `remove`: Remove a pod and its containers.
*   `update`: Update the container images of a pod.

### Targets

*   `<recipe_name>`: The name of a recipe file.
*   `@<group_name>`: The name of a recipe group defined in a configuration file.

### Options

*   `--config <config_name>`: Use a specific configuration file.
*   `--help`: Display the help message.
*   `--simulate`: Force simulate mode, overrides config file option.

## Configuration

Configuration is done in a specific file. This file allows you to define:

*   `simulate`: If `true`, commands will be printed but not executed (replaces older `dryrun` terminology).
*   `recipes`: The path to your recipe files and `groups` of recipes.
*   `pods`: The default path for pod data.

An example configuration can be found in [config.lua](config.lua).

## Recipes

Recipes are Lua files that define a pod and its containers. An example recipe can be found in [recipe.lua](recipe.lua).

## Testing

To run the entire test suite, execute the following command:

```bash
lua test_suite.lua
```

To run a single test by its internal ID, or run a whole suite by its file name, provide the identifier or file name as an argument:

```bash
lua test_suite.lua T00101
lua test_suite.lua suite_001_argument_options.lua
```

## License

This project is licensed under the GNU General Public License v3.0. See the `LICENSE` file for details.
