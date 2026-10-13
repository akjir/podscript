# PodScript

[![Platform](https://img.shields.io/badge/platform-Linux-blue.svg)](https://www.kernel.org)
[![Lua Version](https://img.shields.io/badge/lua-5.5%2B-blue.svg)](https://www.lua.org)
[![Podman Version](https://img.shields.io/badge/podman-5.8.0%2B-purple.svg)](https://podman.io)
[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-green.svg)](LICENSE)

PodScript manages Podman pods and containers through declarative Lua recipes. It translates structured Lua tables into deterministic Podman CLI commands without external dependencies or background daemons.

## Features

- Declarative Lua recipes for pods, published ports, volumes, and containers.
- Deterministic lifecycle execution (top-to-bottom startup, bottom-to-top shutdown).
- Recipe groups (`@group`) with nested group expansion and duplicate elimination.
- Dry-run simulation (`--simulate`) to preview generated Podman commands before execution.
- Built-in modes for runtime status, log streaming, interactive shell access, maintenance commands, and image pruning.
- Zero external dependencies in a single standalone file (`pods.lua`).

## Requirements

| Component        | Minimum Version |
| :--------------- | :-------------- |
| Operating System | Linux           |
| Lua              | 5.5             |
| Podman           | 5.8.0           |

## Installation

Download the standalone script into your working directory:

```bash
mkdir -p podscript && cd podscript
curl -fsSL https://raw.githubusercontent.com/akjir/podscript/refs/heads/main/pods.lua -o pods.lua
```

### CLI Wrapper (Optional)

Create a wrapper script in `/usr/local/bin/pods` to run `pods` from anywhere:

```bash
sudo tee /usr/local/bin/pods > /dev/null << 'EOF'
#!/bin/bash
PODSCRIPT_DIR="/path/to/podscript"
cd "${PODSCRIPT_DIR}" || exit 1
exec lua pods.lua "$@"
EOF
sudo chmod +x /usr/local/bin/pods
```

### Shell Autocompletion (Optional)

Download and source the Bash completion script:

```bash
curl -fsSL https://raw.githubusercontent.com/akjir/podscript/refs/heads/main/.pods-completion.bash -o .pods-completion.bash
source .pods-completion.bash
```

## Quick Start

1. Initialize a new working directory with default `config.lua` and `recipe.lua` templates:

```bash
pods init
```

2. Preview the Podman commands that PodScript generates for the recipe:

```bash
pods create recipe --simulate
```

> [!NOTE]
> The generated `config.lua` sets `simulate = true` by default as a safeguard. Set `simulate = false` in `config.lua` when you are ready to execute commands on your system.

3. Create the pod, check its status, and inspect container logs:

```bash
pods create recipe
pods status
pods logs recipe
```

4. Stop and remove the pod and its containers:

```bash
pods remove recipe
```

## Configuration and Recipes

### Configuration (`config.lua`)

The configuration file defines the default text editor, simulation mode, base directories, and recipe groups. Every active recipe must belong to at least one group. Groups can also reference other groups with the `@` prefix.

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

### Recipes (`<name>.lua`)

A recipe defines a single pod and an ordered list of containers. Containers are created from top to bottom and removed in reverse order.

```lua
return {
    name = "Example Web Stack",
    description = "Web application and database stack.",

    pod = {
        name = "web-stack",
        path = "/pods/web-stack",
        registry = "docker.io",
        publish = {
            { 8080, 80, "TCP" },
        },
        commands = {
            migrate = {
                description = "Run database migrations.",
                container = "*db",
                user = "dbuser",
                execute = "app-cli migrate",
            },
        },
        options = {
            "--userns=keep-id",
        },
    },

    containers = {
        {
            name = "*db",
            restart = "always",
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
            restart = "always",
            image = "example/example-app:latest",
            commands = { "start-server.sh" },
        },
    },
}
```

Key recipe conventions:
- **Container Naming:** Names prefixed with `*` (such as `*db`) expand to `<pod.name>-<name>` (`web-stack-db`). If omitted, the container index is used (`web-stack-1`).
- **Volume Paths:** Relative host paths (such as `"data"`) resolve against `pod.path` (or `<pods.path>/<pod.name>` if `pod.path` is omitted).
- **Custom Flags:** Any Podman flags not directly modeled by PodScript can be passed via `pod.options` and `container.options`.

## CLI Overview

General syntax:

```bash
pods [MODE] [OPTIONS] [ACTION] [TARGETS...]
```

| Mode        | Actions                                                    | Target                        | Description                                                  |
| :---------- | :--------------------------------------------------------- | :---------------------------- | :----------------------------------------------------------- |
| `(default)` | `create`, `recreate`, `remove`, `update`, `status`, `help` | `<recipe>`, `@<group>`        | Manage pod lifecycles and display container runtime status.  |
| `logs`      | `show`, `follow`, `help`                                   | `<recipe>[/<container>]`      | Display or stream pod and container logs.                    |
| `connect`   | `shell`, `help`                                            | `<recipe>[/<container>]`      | Open an interactive shell inside a running container.        |
| `command`   | `list`, `exec`, `help`                                     | `<recipe> [<command>\|<idx>]` | List or execute maintenance commands defined in a recipe.    |
| `recipe`    | `list`, `show`, `edit`, `help`                             | `[<recipe>]`                  | List configured recipes, or view and edit a recipe file.     |
| `config`    | `show`, `edit`, `help`                                     | `-`                           | Display the validated configuration tree or edit the config. |
| `image`     | `prune`, `help`                                            | `-`                           | Preview and remove dangling or unused container images.      |
| `init`      | `help`                                                     | `-`                           | Generate default `config.lua` and `recipe.lua` templates.    |

Global options available across modes:
- `--config=<name>`: Load an alternative configuration file by name or path.
- `--debug`: Enable verbose debug output.
- `--simulate`: Print generated Podman commands without executing them.

For complete command documentation, mode-specific flags, and targeting rules, see [USAGE.md](USAGE.md).

## Development

Source files are located in `src/pods/`. Do not edit `pods.lua` directly; it is generated by the build script.

```bash
# Run dev tests, build tests, build pods.lua, and run release tests
./task verify

# Run specific test suites
./task test
./task test dev
./task test release

# Build standalone pods.lua
./task build
```

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.

PodScript is provided "as is", without warranty of any kind. Use at your own risk.
