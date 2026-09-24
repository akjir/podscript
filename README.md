# PodScript

[![Platform](https://img.shields.io/badge/platform-Linux-blue.svg)](https://www.kernel.org)
[![Lua Version](https://img.shields.io/badge/lua-5.5%2B-blue.svg)](https://www.lua.org)
[![Podman Version](https://img.shields.io/badge/podman-5.8.0%2B-purple.svg)](https://podman.io)
[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-green.svg)](LICENSE)

A lightweight, declarative pod and container manager for Podman, written in Lua with zero external dependencies.

PodScript simplifies container operations by replacing complex shell scripts and repetitive CLI invocations with structured Lua recipe files. It provides deterministic lifecycle ordering, recipe grouping, container maintenance tasks, and dry-run simulation out of the box.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
  - [Recipes](#recipes)
  - [Lifecycle Ordering](#lifecycle-ordering)
  - [Recipe Groups](#recipe-groups)
- [CLI Reference](#cli-reference)
- [Development](#development)
  - [Building](#building)
  - [Testing](#testing)
- [Disclaimer](#disclaimer)
- [License](#license)

---

## Features

- **Declarative Recipes:** Define pods and containers using concise, readable Lua tables.
- **Deterministic Lifecycle:** Sequential container startup (top-to-bottom) and reverse shutdown (bottom-to-top) for reliable multi-container dependencies.
- **Dry-Run Simulation:** Preview exact Podman commands before execution using the `simulate` mode or the `--simulate` flag.
- **Recipe Groups:** Aggregate multiple recipes into logical groups (`@group_name`) to orchestrate entire stacks in a single command.
- **Container Maintenance Commands:** Define and execute ad-hoc maintenance tasks inside running containers by command name or numeric index.
- **Built-in Inspection & Editing:** Quickly inspect (`print`) or modify (`edit`) configuration files and recipes via integrated CLI modes.
- **Zero External Dependencies:** Ships as a self-contained single script (`pods.lua`) requiring only Lua and Podman.
- **Safe Execution:** Automated shell argument escaping, prerequisite validation, and privilege checks.

---

## Requirements

| Requirement | Supported Version | Details |
| :--- | :--- | :--- |
| **Operating System** | Linux | Enforced on startup |
| **Lua** | 5.5 or higher | Uses Lua 5.5 features (`global<const>`, `table.create`) |
| **Podman** | 5.8.0 or higher | Tested with rootful and rootless pod operations |

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/akjir/podscript.git
cd podscript
```

### 2. Set Up a PATH Wrapper (Recommended)

To run PodScript from any directory, create a launcher script in your `PATH` (such as `/usr/local/bin/pods` or `~/.local/bin/pods`):

```bash
sudo tee /usr/local/bin/pods > /dev/null << 'EOF'
#!/bin/bash
PODSCRIPT_DIR="/path/to/podscript"
cd "${PODSCRIPT_DIR}" || exit 1
exec lua pods.lua "$@"
EOF

sudo chmod +x /usr/local/bin/pods
```

Replace `/path/to/podscript` with the absolute path to your PodScript directory.

---

## Quick Start

### 1. Create a Recipe File

Create a recipe file (e.g., `web-service.lua`) in your recipe search directory:

```lua
return {
    name = "Web Service Stack",
    pod = {
        name = "web-service",
        publish = {
            { 8080, 80, "TCP" },
        },
    },
    containers = {
        {
            name = "*db",
            image = "docker.io/library/redis:alpine",
            restart = "always",
        },
        {
            name = "*app",
            image = "docker.io/library/nginx:alpine",
            restart = "always",
        },
    },
}
```

### 2. Manage the Pod

```bash
# Preview the Podman commands without executing them
pods simulate create web-service

# Create and start the pod and containers
pods create web-service

# Pull updated images and recreate containers if changed
pods update web-service

# Stop and remove the pod and containers
pods remove web-service
```

---

## Core Concepts

### Recipes

Recipes are Lua files returning a declarative table defining a pod and its containers:

- **Pod Configuration (`pod`):** Defines pod name, publish ports, network options, and shared volumes or paths.
- **Containers (`containers`):** An array of container definitions including image names, registries, environment variables, restart policies, and custom launch options.
- **Maintenance Commands (`pod.commands`):** Dedicated tasks executed via `podman exec` inside specific containers.

See [recipe.lua](recipe.lua) for a complete recipe template.

### Lifecycle Ordering

Container ordering within a recipe is deterministic:

1. **Creation & Startup:** Containers are created and started sequentially from first to last (top-to-bottom).
2. **Shutdown & Removal:** When stopping or removing a pod, containers are stopped and removed in reverse order (bottom-to-top).
3. **Recreation:** Recreating a pod executes the reverse shutdown followed by sequential startup.

This ensures services with dependencies (such as a database initialized before an application service) start and stop reliably.

### Recipe Groups

Configure recipe collections in `config.lua` to manage multiple applications simultaneously:

```lua
return {
    recipes = {
        groups = {
            core = { "database", "redis" },
            web  = { "api-server", "frontend" },
            all  = { "@core", "@web" },
        },
    },
}
```

Execute commands against entire groups using the `@` prefix:

```bash
pods create @core
pods update @all
```

When targeting multiple recipes or groups, PodScript follows a **first appearance** rule to guarantee no recipe executes more than once.

---

## CLI Reference

PodScript follows a mode-driven command structure:

```bash
pods [MODE] [OPTIONS] [ACTION] [TARGETS]
```

### Modes

| Mode | Description |
| :--- | :--- |
| `(default)` | Executes lifecycle actions (`create`, `recreate`, `remove`, `update`) on specified targets. |
| `simulate` | Previews all generated commands without executing them. |
| `config` | Displays (`print`) or opens (`edit`) the active configuration file. |
| `recipe` | Displays (`print`) or opens (`edit`) a specific recipe file. |
| `command` | Lists (`list`) or executes maintenance commands defined in a recipe. |
| `help` | Displays command-line help and usage information. |

### Global Options

- `--config=<name>`: Load an alternative configuration file (e.g., `--config=staging`).
- `--debug`: Enable verbose debug logging for troubleshooting.

For complete syntax, option matrices, and detailed examples, see [USAGE.md](USAGE.md).

---

## Development

The codebase is organized modularly under `src/` and compiled into a standalone, single-file release script (`pods.lua`).

> [!IMPORTANT]
> Never edit `pods.lua` directly. All modifications must be made within the `src/` directory.

### Building

To bundle the modular source files into the single-file release version:

```bash
lua build.lua
```

The build script concatenates modules, handles build directives, and localizes internal functions.

### Testing

PodScript includes a comprehensive test framework:

```bash
# Run tests against the release script (pods.lua)
lua test.lua

# Run tests against development sources (src/)
lua test.lua --dev

# Run a specific test suite or test ID
lua test.lua 001
lua test.lua 00101 --dev
```

---

## Disclaimer

PodScript is provided "as is", without warranty of any kind, express or implied. Use this tool at your own risk. It is strongly recommended to maintain current backups of your data and container configurations. The authors are not responsible for any data loss, service interruption, or system instability.

---

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.
