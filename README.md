# PodScript

A simple Lua script for managing Podman containers and pods using declarative recipe files.

## Disclaimer

This is a personal hobby project created for the primary purposes of learning Lua and exploring the use of AI-assisted development tools in a practical coding scenario.

**WARNING:** This software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

**IMPORTANT:** Use this script at your own risk. It is strongly recommended to maintain current backups of your data and container configurations before using this script. The author is not responsible for any data loss, corruption, or system instability.

## Features

*   Manage Podman pods and containers with simple commands (`create`, `recreate`, `remove`, `update`).
*   Define pods and containers in declarative Lua recipe files.
*   Configure container specifics individually like registries, publish ports, lifecycle options, volumes, restart policies, and custom launch commands.
*   Organize recipes into groups for managing multiple applications at once.
*   Flexible configuration through a configuration file.
*   Simulate mode to preview commands before execution.

## Specifications

*   **Operating System:** Linux (Only Linux is supported).
*   **Lua Version:** Lua 5.4 or higher.
*   **Podman Version:** 5.8.0 or higher.

## Usage

Detailed information on how to use PodScript, including modes, actions, options, and targets, can be found in [USAGE.md](USAGE.md).

## Configuration

Configuration is done in a specific file. This file allows you to define:

*   `simulate`: If `true`, commands will be printed but not executed.
*   `recipes`: The path to your recipe files and `groups` of recipes.
*   `pods`: The default path for pod data.

An example configuration can be found in [config.lua](config.lua).

## Recipes

Recipes are Lua files that define a pod and its containers. An example recipe can be found in [recipe.lua](recipe.lua).

The order in which containers are defined within a recipe is significant:
*   **Creation & Startup:** Containers are created and started in the order they are listed.
*   **Removal & Shutdown:** When removing a pod, the containers are stopped and removed in reverse order.
*   **Recreation:** Recreating a pod follows both behaviors—containers are first stopped and removed in reverse order, then created and started in the original order.

## Helper Script

For easier usage of PodScript from any directory, you can create a helper script in your PATH (e.g., `/usr/local/bin/pods`).

**Example installation:**

1. Create and edit the helper script:
   ```bash
   sudo vi /usr/local/bin/pods
   ```

2. Add the following content, ensuring the `cd` command points to your PodScript installation directory:
   ```bash
   #!/bin/bash

   cd ~/podscript/
   lua pods.lua "$@"
   ```

3. Make the script executable:
   ```bash
   sudo chmod +x /usr/local/bin/pods
   ```

This allows you to run PodScript commands simply by typing `pods` from any location:
   ```bash
   pods create recipe
   ```

## Development

The PodScript project follows a modular development approach. The source code is organized into separate modules within the `src/` directory for better maintainability and clarity.

To bundle these modular source files into the single-file release version (`pods.lua`), use the provided build script:

```bash
lua build.lua
```

**IMPORTANT:** Always make code changes within the `src/` directory. The `pods.lua` file is automatically generated and should not be edited directly.

## Testing

### Testing Modes

The test suite can be run in two modes:

*   **Release Mode (Default):** Tests the generated `pods.lua` file.
    ```bash
    lua test.lua
    ```
*   **Development Mode:** Tests the modular source files in `src/` directly.
    ```bash
    lua test.lua --dev
    ```

### Running Specific Tests

To run a single test or a specific suite:

```bash
lua test.lua T00101
lua test.lua suite_001_argument_options.lua
```

These also support the `--dev` flag if you want to test the source files.

## License

This project is licensed under the GNU General Public License v3.0. See the `LICENSE` file for details.
