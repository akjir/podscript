# PodScript Usage Guide

This guide documents all implemented features, configuration schemas, recipe definitions, targeting rules, and command-line modes of PodScript.

## Table of Contents

- [Command Syntax](#command-syntax)
  - [Modes Overview](#modes-overview)
  - [Global Options](#global-options)
- [Configuration Reference](#configuration-reference)
- [Recipe Reference](#recipe-reference)
  - [Top-Level Fields](#top-level-fields)
  - [Pod Fields](#pod-fields)
  - [Container Fields](#container-fields)
  - [Recipe Example](#recipe-example)
- [Targeting Rules](#targeting-rules)
  - [Recipe and Group Targets](#recipe-and-group-targets)
  - [Container Targets](#container-targets)
- [Default Mode](#default-mode)
  - [Actions](#actions)
  - [Options](#options)
  - [Usage](#usage)
- [Logs Mode](#logs-mode)
  - [Actions](#actions-1)
  - [Options](#options-1)
  - [Usage](#usage-1)
- [Connect Mode](#connect-mode)
  - [Actions](#actions-2)
  - [Options](#options-2)
  - [Usage](#usage-2)
- [Command Mode](#command-mode)
  - [Actions](#actions-3)
  - [Options](#options-3)
  - [Usage](#usage-3)
- [Recipe Mode](#recipe-mode)
  - [Actions](#actions-4)
  - [Options](#options-4)
  - [Usage](#usage-4)
- [Config Mode](#config-mode)
  - [Actions](#actions-5)
  - [Options](#options-5)
  - [Usage](#usage-5)
- [Image Mode](#image-mode)
  - [Actions](#actions-6)
  - [Options](#options-6)
  - [Usage](#usage-6)
- [Init Mode](#init-mode)
  - [Actions](#actions-7)
  - [Options](#options-7)
  - [Usage](#usage-7)

## Command Syntax

Invoke PodScript through the `pods` wrapper or directly with the Lua interpreter:

```bash
pods [MODE] [OPTIONS] [ACTION] [TARGETS...]
lua pods.lua [MODE] [OPTIONS] [ACTION] [TARGETS...]
```

Argument parsing follows these rules:

- **Mode Resolution:** If the first positional argument matches a mode name (`command`, `config`, `connect`, `image`, `init`, `logs`, `recipe`), that mode is selected. Otherwise, PodScript selects the [Default Mode](#default-mode) and treats the first positional argument as the action.
- **No Arguments:** Running `pods` without arguments executes `pods help`.
- **Option Placement:** Options prefixed with `--` can appear anywhere in the command line.
- **Configuration Bypass:** The `init` mode, `image` mode, all `help` actions (`pods help`, `pods <mode> help`, `pods status help`), and parameterless calls to `command`, `connect`, or `logs` run without loading `config.lua`.
- **Privilege Check:** When executed with elevated privileges (`sudo` or `root`), PodScript prints a warning and requires interactive confirmation (`yes`) before running.

### Modes Overview

| Mode        | Actions                                                    | Target                        | Description                                                       |
| :---------- | :--------------------------------------------------------- | :---------------------------- | :---------------------------------------------------------------- |
| `(default)` | `create`, `recreate`, `remove`, `update`, `status`, `help` | `<recipe>`, `@<group>`        | Manage pod lifecycles and inspect runtime container status.       |
| `logs`      | `show`, `follow`, `help`                                   | `<recipe>[/<container>]`      | Display or follow logs for a pod or a specific container.         |
| `connect`   | `shell`, `help`                                            | `<recipe>[/<container>]`      | Open an interactive shell inside a running container.             |
| `command`   | `list`, `exec`, `help`                                     | `<recipe> [<command>\|<idx>]` | List or execute maintenance commands defined in a recipe.         |
| `recipe`    | `list`, `show`, `edit`, `help`                             | `[<recipe>]`                  | List configured recipes, or display and edit a recipe file.       |
| `config`    | `show`, `edit`, `help`                                     | `-`                           | Validate and display the active configuration tree or edit it.    |
| `image`     | `prune`, `help`                                            | `-`                           | Preview and remove dangling or unused container images.           |
| `init`      | `help`                                                     | `-`                           | Generate initial `config.lua` and `recipe.lua` template files.    |

### Global Options

| Option            | Description                                                                              |
| :---------------- | :--------------------------------------------------------------------------------------- |
| `--config=<name>` | Load an alternative configuration file by name or path (with or without `.lua`).         |
| `--debug`         | Enable verbose debug output for argument parsing, path resolution, and target expansion. |
| `--simulate`      | Print generated Podman and editor commands without executing them on the host.           |

## Configuration Reference

By default, PodScript loads `./config.lua`. Use `--config=<name>` to load an alternative file (for example, `--config=staging` loads `./staging.lua`).

| Key              | Type      | Default  | Required | Description                                                                          |
| :--------------- | :-------- | :------- | :------- | :----------------------------------------------------------------------------------- |
| `editor`         | `string`  | `""`     | No       | External editor command executed by `pods config edit` and `pods recipe edit`.       |
| `simulate`       | `boolean` | `true`   | No       | Enable dry-run simulation mode globally unless explicitly set to `false`.            |
| `pods.path`      | `string`  | `""`     | No       | Default base directory for pod volume paths when a recipe omits `pod.path`.          |
| `recipes.path`   | `string`  | `"."`    | No       | Directory path where PodScript searches for `<recipe>.lua` files.                    |
| `recipes.groups` | `table`   | `{}`     | Yes      | Non-empty table mapping group names to arrays of recipe names or `@<group>` entries. |

> [!IMPORTANT]
> Every recipe must belong to at least one group in `recipes.groups` to be recognized by lifecycle commands and `recipe` mode actions.

```lua
return {
    editor = "vim",
    simulate = false,
    pods = {
        path = "/pods",
    },
    recipes = {
        path = ".",
        groups = {
            backend = {
                "db-server",
                "cache-server",
            },
            all = {
                "@backend",
                "example-app",
            },
        },
    },
}
```

## Recipe Reference

Each recipe is a Lua file (`<recipe>.lua`) in `recipes.path` that returns a table describing one pod and its containers.

### Top-Level Fields

| Field         | Type     | Required | Description                                                                 |
| :------------ | :------- | :------- | :-------------------------------------------------------------------------- |
| `name`        | `string` | Yes      | Human-readable display name of the recipe.                                  |
| `description` | `string` | No       | Summary displayed by `pods recipe list`.                                    |
| `pod`         | `table`  | Yes      | Pod configuration table.                                                    |
| `containers`  | `table`  | Yes      | Non-empty ordered array of container configuration tables.                  |

### Pod Fields

| Field          | Type     | Required | Description                                                                                   |
| :------------- | :------- | :------- | :-------------------------------------------------------------------------------------------- |
| `pod.name`     | `string` | No       | Pod name in Podman (normalized to lowercase with underscores); defaults to `recipe.name`.     |
| `pod.registry` | `string` | Yes      | Default image registry prefixed to container images that do not specify `container.registry`. |
| `pod.path`     | `string` | Cond.    | Base host directory for relative volume mounts; defaults to `<pods.path>/<pod.name>`.         |
| `pod.publish`  | `table`  | No       | Array of port mapping tables translated into `--publish` arguments on `podman pod create`.    |
| `pod.options`  | `table`  | No       | Array of raw flag strings appended directly to `podman pod create`.                           |
| `pod.commands` | `table`  | No       | Dictionary of maintenance command definitions executed via `pods command`.                    |

#### Port Publishing (`pod.publish`)

Each entry in `pod.publish` is an array table that maps to a `--publish` flag:

| Entry Format                              | Generated Flag                             |
| :---------------------------------------- | :----------------------------------------- |
| `{ 8080 }` or `{ "", 8080 }`              | `--publish 8080`                           |
| `{ 8080, "TCP" }` or `{ 53, "UDP" }`      | `--publish 8080/TCP` or `--publish 53/UDP` |
| `{ 8080, 80 }`                            | `--publish 8080:80`                        |
| `{ 8080, 80, "TCP" }`                     | `--publish 8080:80/TCP`                    |
| `{ "127.0.0.1:8080", 80, "TCP" }`         | `--publish 127.0.0.1:8080:80/TCP`          |

#### Maintenance Commands (`pod.commands`)

Each key in `pod.commands` defines a named command for `pods command`:

| Field         | Type             | Required | Description                                                                               |
| :------------ | :--------------- | :------- | :---------------------------------------------------------------------------------------- |
| `container`   | `string\|number` | Yes      | Target container by 1-based index (`1`), relative name (`"*db"` or `"db"`), or full name. |
| `execute`     | `string`         | Yes      | Command line executed inside the container via `podman exec -it`.                         |
| `user`        | `string\|number` | No       | Username or UID passed to `podman exec -it -u <user>`.                                    |
| `description` | `string`         | No       | Summary shown in `pods command list` (omitting triggers a warning when listing).          |

### Container Fields

Containers in `containers` are created sequentially from index `1` to `N` and stopped/removed in reverse order from `N` down to `1`.

| Field                | Type      | Required | Description                                                                                 |
| :------------------- | :-------- | :------- | :------------------------------------------------------------------------------------------ |
| `container.image`    | `string`  | Yes      | Image repository and tag (`"example/db-server:latest"`).                                    |
| `container.name`     | `string`  | No       | Container name; supports relative (`"*db"`), explicit (`"custom"`), or automatic naming.    |
| `container.registry` | `string`  | No       | Registry override for this container; falls back to `pod.registry`.                         |
| `container.detach`   | `boolean` | No       | Run container in the background (`--detach`); defaults to `true` unless set to `false`.     |
| `container.restart`  | `string`  | No       | Restart policy passed to `--restart` (for example, `"always"` or `"on-failure"`).           |
| `container.volumes`  | `table`   | No       | Array of volume definitions `{ <host_path>, <container_path>, [<options>] }`.               |
| `container.options`  | `table`   | No       | Array of raw flag strings appended directly to `podman run`.                                |
| `container.commands` | `table`   | No       | Array of command and argument strings appended after the image in `podman run`.             |

#### Container Naming Rules

- **Omitted or `""`:** Expands to `<pod.name>-<index>` (for example, `example-stack-1`).
- **Prefixed with `*`:** Expands to `<pod.name>-<suffix>` (for example, `"*db"` becomes `example-stack-db`).
- **Without `*`:** Normalized (lowercase, spaces replaced with `_`) and used as the exact container name.

#### Volume Mount Rules (`container.volumes`)

Each entry is a 2-element or 3-element array `{ host_dir, container_dir, options }`:

| `host_dir` Value         | Resolution                                       | Generated `--volume` Value                    |
| :----------------------- | :----------------------------------------------- | :-------------------------------------------- |
| `""` or `nil`            | Anonymous volume                                 | `<container_dir>[:<options>]`                 |
| `"data"` or `"./data"`   | Resolved against `pod.path`                      | `<pod.path>/data:<container_dir>[:<options>]` |
| `"/var/data"`            | Absolute host path used as-is                    | `/var/data:<container_dir>[:<options>]`       |

### Recipe Example

```lua
return {
    name = "Example Web Stack",
    description = "Web application and database stack.",

    pod = {
        name = "example-stack",
        path = "/pods/example-stack",
        registry = "docker.io",
        publish = {
            { 8080, 80, "TCP" },
        },
        commands = {
            migrate = {
                description = "Run database migrations.",
                container = "*db",
                user = "dbuser",
                execute = "db-cli -U dbuser -d app -f /migrations/run.sql",
            },
        },
        options = {
            "--userns=keep-id",
        },
    },

    containers = {
        {
            name = "*db",
            detach = true,
            restart = "always",
            registry = "docker.io",
            image = "example/db-server:latest",
            volumes = {
                { "data", "/var/lib/db/data", "Z" },
            },
            options = {
                "--env DB_PASSWORD=secret",
            },
        },
        {
            name = "*app",
            detach = true,
            restart = "always",
            image = "example/example-app:latest",
            commands = { "start-server.sh" },
        },
    },
}
```

## Targeting Rules

### Recipe and Group Targets

The [Default Mode](#default-mode) accepts one or more recipe names (`<recipe>`) or group references (`@<group>`):

- **Sequential Order:** Recipes execute in the exact order they appear after group expansion.
- **First Appearance Rule:** When a recipe appears multiple times across arguments or nested `@<group>` definitions, only its first occurrence is executed and subsequent duplicates are removed.
- **Group Validation:** Every targeted recipe must exist in at least one group in `config.lua`. Container suffixes (`@group/container`) are not valid on groups.

### Container Targets

The `logs`, `connect`, and `command` modes resolve individual containers within a recipe using `<recipe>/<container>` (or `command.container`):

- **Numeric Index:** `example-app/1` selects the first container in `containers`.
- **Relative Name:** `example-app/db` or `example-app/*db` selects `<pod.name>-db`.
- **Absolute Name:** `example-app/example-stack-db` selects the container matching that exact resolved name.
- **Direct Container Name (`connect` only):** If `<target>` contains no `/` and no matching `<target>.lua` file exists in `recipes.path`, `pods connect <target>` connects directly to a running Podman container with that name.

## Default Mode

The default mode executes pod lifecycle operations (`create`, `recreate`, `remove`, `update`) and queries container runtime status (`status`). Omit the mode name to invoke default mode.

```bash
pods [OPTIONS] <action> [TARGETS...]
```

### Actions

| Action     | Description                                                                                      |
| :--------- | :----------------------------------------------------------------------------------------------- |
| `create`   | Create the pod and start all defined containers from top to bottom.                              |
| `help`     | Display command-line syntax, modes, options, and actions for the default mode.                   |
| `recreate` | Stop and remove all containers in reverse order, remove the pod, and create the pod stack again. |
| `remove`   | Stop and remove all containers in reverse order, then remove the pod.                            |
| `status`   | Display a formatted status table of managed containers (or status help via `pods status help`).  |
| `update`   | Pull the latest container images from their configured registries for all targeted recipes.      |

### Options

| Option            | Description                                                                             |
| :---------------- | :-------------------------------------------------------------------------------------- |
| `--all`           | Include unmanaged Podman containers in `status` output alongside managed containers.    |
| `--config=<name>` | Load an alternative configuration file by name or path.                                 |
| `--debug`         | Enable verbose debug logging.                                                           |
| `--full`          | Append `COMMAND` and `PORTS` columns to the `status` output table.                      |
| `--simulate`      | Print generated Podman commands without executing them.                                 |

### Usage

```bash
# Display general help (or run 'pods' without arguments)
pods help

# Create a pod and its containers from a single recipe
pods create example-app

# Preview the Podman commands for creating a group of pods without executing them
pods create @backend --simulate

# Pull the latest images for a group and recreate its pods
pods update @backend
pods recreate @backend

# Stop and remove multiple recipes and groups in order
pods remove example-app @backend

# Show runtime status for all configured recipes
pods status

# Show extended status (including COMMAND and PORTS) for a specific recipe
pods status --full example-app

# Show status for all containers on the host, including unmanaged containers
pods status --all

# Display help specific to the status action
pods status help

# Run lifecycle actions using an alternative configuration and debug logging
pods --config=staging --debug recreate example-app
```

## Logs Mode

The `logs` mode fetches or streams container logs for a recipe's pod or a single container within that pod via `podman pod logs`.

```bash
pods logs [OPTIONS] [ACTION] <recipe>[/<container>]
```

### Actions

| Action   | Description                                                                         |
| :------- | :---------------------------------------------------------------------------------- |
| `follow` | Stream log output continuously until interrupted (`-f`).                            |
| `help`   | Display command-line help for `logs` mode (default when called without arguments).  |
| `show`   | Output logs and exit immediately (default when `<recipe>` is given without action). |

### Options

| Option            | Description                                                                      |
| :---------------- | :------------------------------------------------------------------------------- |
| `--config=<name>` | Load an alternative configuration file by name or path.                          |
| `--debug`         | Enable verbose debug logging.                                                    |
| `--simulate`      | Print the generated `podman pod logs` command without executing it.              |
| `--since=<time>`  | Show logs generated since the given duration (such as `15m`) or timestamp.       |
| `--tail=<n>`      | Show only the last `<n>` lines of log output.                                    |
| `--timestamps`    | Prepend timestamps to each log line.                                             |
| `--until=<time>`  | Show logs generated before the given duration or timestamp.                      |

### Usage

```bash
# Display logs mode help
pods logs help

# Show logs for all containers in a recipe (implicitly uses 'show')
pods logs example-app
pods logs show example-app

# Follow live logs for a specific container by relative name
pods logs follow example-app/db

# Show the last 100 log lines with timestamps for the first container
pods logs --tail=100 --timestamps show example-app/1

# Filter logs to a specific time window
pods logs --since=1h --until=10m example-app

# Preview the generated Podman logs command using an alternative config
pods --config=staging --debug logs follow example-app/app --simulate
```

## Connect Mode

The `connect` mode opens an interactive shell (`bash` if available, falling back to `sh`) inside a running container via `podman exec -it`.

```bash
pods connect [OPTIONS] [ACTION] <target>
```

### Actions

| Action  | Description                                                                              |
| :------ | :--------------------------------------------------------------------------------------- |
| `help`  | Display command-line help for `connect` mode (default when called without arguments).    |
| `shell` | Open an interactive shell inside the target container (default when action is omitted).  |

### Options

| Option            | Description                                                            |
| :---------------- | :--------------------------------------------------------------------- |
| `--config=<name>` | Load an alternative configuration file by name or path.                |
| `--debug`         | Enable verbose debug logging.                                          |
| `--simulate`      | Print the generated `podman exec` command without executing it.        |

### Usage

```bash
# Display connect mode help
pods connect help

# Connect to a single-container recipe (implicitly uses 'shell')
pods connect db-server
pods connect shell db-server

# Connect to a specific container in a multi-container recipe by relative name or index
pods connect example-app/db
pods connect example-app/2

# Connect directly to an unmanaged Podman container by its exact container name
pods connect custom-container-name

# Preview the connection command with debug output and an alternative config
pods --config=staging --debug connect example-app/db --simulate
```

## Command Mode

The `command` mode lists or executes maintenance commands declared under `pod.commands` in a recipe via `podman exec -it`.

```bash
pods command [OPTIONS] [ACTION] <recipe> [<command>|<index>]
```

### Actions

| Action | Description                                                                                           |
| :----- | :---------------------------------------------------------------------------------------------------- |
| `exec` | Execute a command by name or 1-based index (default when `<command>` or `<index>` is provided).       |
| `help` | Display command-line help for `command` mode (default when called without arguments).                 |
| `list` | List all valid commands sorted alphabetically with their index (default when `<command>` is omitted). |

### Options

| Option            | Description                                                            |
| :---------------- | :--------------------------------------------------------------------- |
| `--config=<name>` | Load an alternative configuration file by name or path.                |
| `--debug`         | Enable verbose debug logging.                                          |
| `--simulate`      | Print the generated `podman exec` command without executing it.        |

### Usage

```bash
# Display command mode help
pods command help

# List all maintenance commands defined in a recipe
pods command list example-app
pods command example-app

# Execute a maintenance command by its key name
pods command exec example-app migrate
pods command example-app migrate

# Execute a maintenance command by its 1-based list index
pods command exec example-app 1

# Preview the generated podman exec command using an alternative config
pods --config=staging --debug command exec example-app migrate --simulate
```

## Recipe Mode

The `recipe` mode lists configured recipes, inspects recipe file contents with line numbers, or opens a recipe file in the configured editor.

```bash
pods recipe [OPTIONS] [ACTION] [<recipe>]
```

### Actions

| Action | Description                                                                                      |
| :----- | :----------------------------------------------------------------------------------------------- |
| `edit` | Open the specified recipe file in the external editor configured in `config.lua`.                |
| `help` | Display command-line help for `recipe` mode.                                                     |
| `list` | List all recipes registered in `config.lua` with descriptions and file status (default action).  |
| `show` | Print the recipe file with line numbers (default when `<recipe>` is given without an action).    |

### Options

| Option            | Description                                                                             |
| :---------------- | :-------------------------------------------------------------------------------------- |
| `--all`           | Include unreferenced `.lua` files found in `recipes.path` when running `recipe list`.   |
| `--config=<name>` | Load an alternative configuration file by name or path.                                 |
| `--debug`         | Enable verbose debug logging.                                                           |
| `--simulate`      | Print the editor command without executing it when running `recipe edit`.               |

### Usage

```bash
# Display recipe mode help
pods recipe help

# List all configured recipes and their file status
pods recipe
pods recipe list

# List configured recipes plus unreferenced .lua files in the recipes directory
pods recipe list --all

# Print a recipe file with line numbers
pods recipe show example-app
pods recipe example-app

# Open a recipe file in the configured text editor
pods recipe edit example-app

# Preview the editor command for a recipe in an alternative config
pods --config=staging --debug recipe edit example-app --simulate
```

## Config Mode

The `config` mode validates and displays the active configuration (including directory status, group hierarchy trees, and missing or unreferenced recipe warnings) or opens the configuration file in the configured editor.

```bash
pods config [OPTIONS] [ACTION]
```

### Actions

| Action | Description                                                                                |
| :----- | :----------------------------------------------------------------------------------------- |
| `edit` | Open the active configuration file in the external editor defined by `editor`.             |
| `help` | Display command-line help for `config` mode.                                               |
| `show` | Display the validated configuration tree and validation summary (default when omitted).    |

### Options

| Option            | Description                                                               |
| :---------------- | :------------------------------------------------------------------------ |
| `--config=<name>` | Target an alternative configuration file by name or path.                 |
| `--debug`         | Enable verbose debug logging.                                             |
| `--simulate`      | Print the editor command without executing it when running `config edit`. |

### Usage

```bash
# Display config mode help
pods config help

# Show the active configuration diagnostic tree and validation summary
pods config
pods config show

# Open the active configuration file in the configured editor
pods config edit

# Inspect or simulate editing an alternative configuration file
pods --config=staging config show
pods --config=staging --debug config edit --simulate
```

## Image Mode

The `image` mode previews and removes unused container images on the host. Podman never removes images attached to existing (running or stopped) containers. This mode does not require `config.lua`.

```bash
pods image [OPTIONS] [ACTION]
```

### Actions

| Action  | Description                                                                             |
| :------ | :-------------------------------------------------------------------------------------- |
| `help`  | Display command-line help for `image` mode (default when called without arguments).     |
| `prune` | Remove unused dangling container images (or all unused images when `--all` is passed).  |

### Options

| Option       | Description                                                                                      |
| :----------- | :----------------------------------------------------------------------------------------------- |
| `--all`      | Target all unused images (including tagged images not used by any container), not just dangling. |
| `--debug`    | Enable verbose debug logging.                                                                    |
| `--force`    | Skip the interactive confirmation prompt before pruning images.                                  |
| `--preview`  | List unused images that would be removed and calculate total reclaimable disk space.             |
| `--simulate` | Print the `podman image prune` command without executing it.                                     |

### Usage

```bash
# Display image mode help
pods image help

# Preview dangling images and reclaimable disk space without deleting anything
pods image prune --preview

# Preview all unused images (both dangling and unreferenced tagged images)
pods image prune --all --preview

# Prune dangling images with interactive confirmation
pods image prune

# Prune all unused images without confirmation
pods image prune --all --force

# Preview the generated podman image prune command
pods --debug image prune --all --simulate
```

## Init Mode

The `init` mode initializes a directory by creating `recipe.lua` and `config.lua`. If either target file already exists, `pods init` aborts with an error without overwriting existing files.

```bash
pods init [OPTIONS] [ACTION]
```

### Actions

| Action   | Description                                                                             |
| :------- | :-------------------------------------------------------------------------------------- |
| `(none)` | Create `./recipe.lua` and `./config.lua` (default when called without an action).       |
| `help`   | Display command-line help for `init` mode.                                              |

### Options

| Option            | Description                                                                             |
| :---------------- | :-------------------------------------------------------------------------------------- |
| `--config=<name>` | Create the configuration file under the specified name or path instead of `config.lua`. |
| `--debug`         | Enable verbose debug logging.                                                           |

### Usage

```bash
# Generate default config.lua and recipe.lua in the current directory
pods init

# Generate recipe.lua and a custom staging.lua configuration file
pods --config=staging --debug init

# Display init mode help
pods init help
```
