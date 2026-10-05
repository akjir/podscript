# PodScript

[![Platform](https://img.shields.io/badge/platform-Linux-blue.svg)](https://www.kernel.org)
[![Lua Version](https://img.shields.io/badge/lua-5.5%2B-blue.svg)](https://www.lua.org)
[![Podman Version](https://img.shields.io/badge/podman-5.8.0%2B-purple.svg)](https://podman.io)
[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-green.svg)](LICENSE)

A script to manage Podman pods and containers using declarative Lua recipes.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
- [CLI Reference](#cli-reference)
- [Development](#development)
- [Disclaimer](#disclaimer)
- [License](#license)

## Features

- Declarative pod and container configuration via Lua tables.
- Deterministic lifecycle ordering (top-to-bottom startup, bottom-to-top shutdown).
- Dry-run simulation flag (`--simulate`) to preview generated Podman commands.
- Configuration grouping (`@group_name`) for batch recipe execution.
- Execution of container-specific maintenance commands.
- Standalone single-file deployment (`pods.lua`) with zero external dependencies.

## Requirements

| Component | Minimum Version | Notes |
| :--- | :--- | :--- |
| Operating System | Linux | Required |
| Lua | 5.5 | Utilizes `global<const>` and `table.create` |
| Podman | 5.8.0 | - |

## Installation

```bash
mkdir -p podscript && cd podscript
curl -fsSL https://raw.githubusercontent.com/akjir/podscript/refs/heads/main/pods.lua -o pods.lua
```

Optional: Create a wrapper script in your PATH.

```bash
sudo tee /usr/local/bin/pods > /dev/null << 'EOF'
#!/bin/bash
PODSCRIPT_DIR="/path/to/podscript"
cd "${PODSCRIPT_DIR}" || exit 1
exec lua pods.lua "$@"
EOF
sudo chmod +x /usr/local/bin/pods
```

## Quick Start

Initialize the project directory with default configurations:

```bash
pods init
```

This generates `config.lua` and a sample `recipe.lua`.

Preview the execution of the generated recipe:

```bash
pods create recipe --simulate
```

Create and start the pod and containers:

```bash
pods create recipe
```

## Core Concepts

### Recipes

Recipes are defined in Lua tables. A recipe specifies a pod, its network configuration, and a sequential list of containers.

```lua
return {
    name = "Example Pod",
    pod = {
        name = "web-service",
        publish = { { 8080, 80, "TCP" } },
    },
    containers = {
        {
            name = "app",
            image = "example:latest",
        },
    },
}
```

### Groups

Recipe groups are defined in `config.lua` to manage multiple recipes at once.

```lua
return {
    recipes = {
        groups = {
            backend = { "db-server", "cache-server" },
        },
    },
}
```

Execute commands on groups using the `@` prefix: `pods create @backend`.

## CLI Reference

| Mode | Action | Target | Description |
| :--- | :--- | :--- | :--- |
| `(default)` | `create`, `recreate`, `remove`, `status`, `update` | `<recipe>`, `@<group>` | Executes lifecycle actions on recipes or groups. |
| `logs` | `show`, `follow` | `<recipe>[/<container>]` | Retrieves or tails container logs. |
| `connect` | `shell` | `<recipe>[/<container>]` | Opens an interactive shell in a container. |
| `command` | `list`, `exec` | `<recipe> [command]` | Executes pre-defined maintenance commands. |
| `init` | - | - | Generates default `config.lua` and `recipe.lua`. |
| `config` | `show`, `edit` | - | Displays or edits the active configuration file. |
| `recipe` | `show`, `edit`, `list` | `<recipe>` | Displays, edits, or lists recipes. |
| `help` | - | - | Displays syntax and usage information. |

Global Options:

- `--config=<name>`: Specify a custom configuration file.
- `--debug`: Enable verbose execution output.
- `--simulate`: Prints generated Podman commands without executing them.

## Development

Source files are located in `src/pods/`. Never edit `pods.lua` directly.

Execute tests and build the release script:

```bash
# Verify (complete cycle: dev tests -> build -> release tests)
./task verify
```

Run tests only (defaults to both dev and release environments):

```bash
./task test
```

Execute tests for a specific environment:

```bash
./task test dev
./task test release
```

Execute a specific test by ID and apply test flags (e.g., `--fail-fast`):

```bash
./task verify 01001
./task verify 01001 --fail-fast
./task test dev 01001 --fail-fast
```

Run the internal test script directly for advanced test flags (e.g., JSON output):

```bash
lua test.lua --fail-fast
lua test.lua --json
```

Build `pods.lua`:

```bash
./task build
lua build.lua --release
```

## Disclaimer

PodScript is provided "as is", without warranty of any kind, express or implied. Use this tool at your own risk. The authors are not responsible for any data loss or system instability.

## License

This project is licensed under the GNU General Public License v3.0. See the LICENSE file for details.
