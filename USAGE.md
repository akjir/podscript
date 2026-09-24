# PodScript CLI Reference & Usage Manual

This document provides a comprehensive command-line reference for PodScript, covering all modes, lifecycle actions, configuration options, targeting rules, and command syntax.

---

## Table of Contents

- [Command Syntax](#command-syntax)
- [Quick Start](#quick-start)
- [Modes Overview](#modes-overview)
- [Global Options](#global-options)
- [Default & Simulate Modes](#default--simulate-modes)
  - [Actions](#actions)
  - [Options](#options)
  - [Targets & Grouping](#targets--grouping)
  - [Usage](#usage)
- [Init Mode](#init-mode)
  - [Actions](#actions-1)
  - [Options](#options-1)
  - [Generated Files](#generated-files)
  - [Usage](#usage-1)
- [Command Mode](#command-mode)
  - [Actions](#actions-2)
  - [Options](#options-2)
  - [Command Definition](#command-definition)
  - [Usage](#usage-2)
- [Config Mode](#config-mode)
  - [Actions](#actions-3)
  - [Options](#options-3)
  - [Editor Configuration](#editor-configuration)
  - [Usage](#usage-3)
- [Recipe Mode](#recipe-mode)
  - [Actions](#actions-4)
  - [Options](#options-4)
  - [Usage](#usage-4)
- [Help Mode](#help-mode)
  - [Usage](#usage-5)
- [Comprehensive Examples](#comprehensive-examples)
  - [Configuration File (`config.lua`)](#configuration-file-configlua)
  - [Basic Pod Lifecycle](#basic-pod-lifecycle)
  - [Dry-Run Simulation](#dry-run-simulation)
  - [Recipe Group Targeting](#recipe-group-targeting)
  - [Container Maintenance Tasks](#container-maintenance-tasks)
  - [Configuration Overrides & Debugging](#configuration-overrides--debugging)

---

## Command Syntax

The general syntax for invoking PodScript is:

```bash
pods [MODE] [OPTIONS] [ACTION] [TARGETS...]
```

Or when running directly via the Lua interpreter:

```bash
lua pods.lua [MODE] [OPTIONS] [ACTION] [TARGETS...]
```

---

## Quick Start

### 1. Initialize Configuration and Recipe

Run the `init` mode to create the default `config.lua` and an example `recipe.lua`:

```bash
pods init
```

This creates:
- `recipe.lua`: An example recipe defining the `web-service` pod.
- `config.lua`: A default configuration with `recipe` registered under the `all` group.

### 2. Inspect the Recipe

The generated `recipe.lua` defines the pod, network publishing, and container specification:

```lua
return {
    name = "Example Pod",
    description = "Example web service pod managed by PodScript.",
    pod = {
        name = "web-service",
        path = "/pods",
        registry = "docker.io",
        publish = {
            { 8080, 80, "TCP" },
        },
    },
    containers = {
        {
            name = "*app",
            detach = true,
            image = "example:latest",
            restart = "always",
        },
    },
}
```

### 3. Manage the Pod

Execute lifecycle commands against your target recipe:

```bash
# Preview the Podman commands without executing them
pods simulate create recipe

# Create and start the pod and containers
pods create recipe

# Pull updated images and recreate containers if changed
pods update recipe

# Stop and remove the pod and containers
pods remove recipe
```

---

## Modes Overview

PodScript is organized into operational modes. When no explicit mode is specified as the first positional argument, PodScript defaults to the **Default Mode**.

| Mode | Description |
| :--- | :--- |
| `(empty)` | **Default Mode**: Executes lifecycle actions on pods and containers defined in recipe files. |
| `simulate` | **Simulate Mode**: Previews all generated Podman commands without executing them. |
| `init` | **Init Mode**: Initializes default `config.lua` and an example `recipe.lua`. |
| `command` | **Command Mode**: Lists or executes maintenance commands defined in a recipe inside a container. |
| `config` | **Config Mode**: Displays or modifies the active PodScript configuration file. |
| `recipe` | **Recipe Mode**: Displays or modifies a specific recipe file. |
| `help` | **Help Mode**: Displays command-line syntax and usage instructions. |

---

## Global Options

The following flags can be supplied across CLI modes:

| Option | Description |
| :--- | :--- |
| `--config=<name>` | Load an alternative configuration file by name or path (without the `.lua` extension). |
| `--debug` | Enable verbose debug logging to output internal state and execution details. |

---

## Default & Simulate Modes

The `default` and `simulate` modes manage container and pod lifecycles. They require an **Action** followed by one or more **Targets**.

Simulate mode operates identically to default mode, except commands are printed rather than executed. It is invoked using the mode keyword `simulate`.

### Actions

| Action | Description |
| :--- | :--- |
| `create` | Create and start a new pod and its containers in the order defined by the recipe. |
| `recreate` | Stop and remove an existing pod and its containers in reverse order, then recreate them anew. |
| `remove` | Stop and remove a running pod and all associated containers in reverse order. |
| `update` | Pull latest container images and recreate the containers if newer versions exist. |

### Options

| Option | Description |
| :--- | :--- |
| `--config=<name>` | Load a specific configuration file (e.g., `--config=staging`). |
| `--debug` | Enable verbose debug output for troubleshooting. |

### Targets & Grouping

Targets indicate which recipes or collections of recipes should receive the specified action:

- `<recipe_name>`: The name of an individual recipe file (without `.lua`).
- `@<group_name>`: A recipe group defined in `config.lua` under `recipes.groups`.

#### Execution Order and First Appearance Rule

When multiple targets or groups are specified, PodScript resolves them according to two key rules:

1. **Sequential Order:** Recipes are executed strictly in the order they are provided or listed within a group.
2. **First Appearance Rule:** If a recipe is targeted multiple times (either directly or via nested groups), only its **first occurrence** in the target sequence is executed. Subsequent duplicates are discarded to prevent redundant operations.

### Usage

```bash
# Create a pod from a single recipe
pods create my-web-server

# Recreate a group of pods
pods recreate @production-apps

# Remove multiple pods and groups in sequence
pods remove frontend @backend-services redis

# Preview pod creation without executing
pods simulate create my-web-server
```

---

## Init Mode

The `init` mode bootstraps a new project directory by generating a default configuration file (`config.lua`) and an example recipe file (`recipe.lua`) with the recipe registered under the `@all` group.

```bash
pods init [OPTIONS]
```

### Actions

| Action | Description |
| :--- | :--- |
| `(empty)` | Creates `config.lua` and an example `recipe.lua`. (Default when omitted). |
| `help` | Display command-line help for init mode. |

### Options

| Option | Description |
| :--- | :--- |
| `--config=<name>` | Specify an alternative configuration filename or path to generate (e.g., `--config=staging`). |
| `--debug` | Enable verbose debug output. |

### Generated Files

1. **`recipe.lua`**: A ready-to-use example recipe defining a `web-service` pod:
   ```lua
   return {
       name = "Example Pod",
       description = "Example web service pod managed by PodScript.",
       pod = {
           name = "web-service",
           path = "/pods",
           registry = "docker.io",
           publish = {
               { 8080, 80, "TCP" },
           },
       },
       containers = {
           {
               name = "*app",
               detach = true,
               image = "example:latest",
               restart = "always",
           },
       },
   }
   ```
2. **`config.lua`**: A configuration file setting the default pod path and defining the recipe under the `all` group:
   ```lua
   return {
       pods = {
           path = "/pods",
       },
       recipes = {
           groups = {
               all = {
                   "recipe",
               },
           },
       },
   }
   ```

> [!NOTE]
> If either `recipe.lua` or the target configuration file already exists, `pods init` terminates with an error to prevent overwriting existing files.

### Usage

```bash
# Initialize default configuration and recipe
pods init

# Initialize with an alternative configuration name
pods --config=staging init

# Display help for init mode
pods init help
```

---

## Command Mode

The `command` mode executes ad-hoc maintenance and administration tasks defined in a recipe inside a running container via `podman exec -it`.

```bash
pods command [OPTIONS] <recipe> [ACTION]
# or in simulation:
pods simulate command [OPTIONS] <recipe> [ACTION]
```

### Actions

| Action | Description |
| :--- | :--- |
| `list` | List all valid maintenance commands defined in the recipe. (Default when omitted). |
| `<name>` | Execute the command matching the specified name defined in the recipe. |
| `<index>` | Execute the command by its 1-based numeric index as listed by `list`. |
| `help` | Display command-line help for command mode. |

### Options

| Option | Description |
| :--- | :--- |
| `--config=<name>` | Load a specific configuration file to resolve recipes and paths. |
| `--debug` | Enable verbose debug output for command resolution. |

### Command Definition

Commands are declared inside the recipe under the `pod.commands` table:

```lua
pod = {
    name = "web-stack",
    commands = {
        migrate = {
            description = "Run database migrations.",
            container   = "*db",
            user        = "postgres",
            execute     = "psql -U postgres -d app -f /migrations/run.sql",
        },
        cache_clear = {
            description = "Clear application cache.",
            container   = 2,
            execute     = "php /var/www/artisan cache:clear",
        },
    },
}
```

- `container`: The target container. Can be an absolute name (`"db"`), a relative name prefixed with `*` (`"*db"` resolves to `<pod_name>-db`), or a 1-based numeric index into the recipe's `containers` array.
- `execute`: The exact command string to execute inside the container.
- `user`: (Optional) User ID or username to execute the command as (`-u`).
- `description`: (Optional) Human-readable explanation shown in command listings.

### Usage

```bash
# List all available commands for a recipe (default action)
pods command web-stack
pods command web-stack list

# Execute a command by name
pods command web-stack migrate

# Execute a command by numeric index
pods command web-stack 1

# Simulate command execution
pods simulate command web-stack migrate
```

---

## Config Mode

The `config` mode provides tools to inspect or edit the active PodScript configuration file.

```bash
pods config [OPTIONS] [ACTION]
```

### Actions

| Action | Description |
| :--- | :--- |
| `print` | Display the contents of the configuration file with line numbers. (Default when omitted). |
| `edit` | Open the active configuration file in the external text editor specified in the config. |
| `help` | Display command-line help for config mode. |

### Options

| Option | Description |
| :--- | :--- |
| `--config=<name>` | Target a specific configuration file instead of the default `config.lua`. |
| `--debug` | Enable verbose debug output. |

### Editor Configuration

To use the `edit` action, define an `editor` command in your `config.lua`:

```lua
return {
    editor = "vim", -- or "nano", "nvim", "code --wait", etc.
    -- ...
}
```

If `editor` is empty or unset, the `edit` action logs an error and aborts.

### Usage

```bash
# Print default configuration with line numbers
pods config print
pods config

# Print an alternative configuration
pods --config=staging config print

# Open the active configuration in the configured editor
pods config edit
```

---

## Recipe Mode

The `recipe` mode provides inspection and editing capabilities for individual recipe files.

```bash
pods recipe [OPTIONS] [ACTION] [RECIPE]
```

### Actions

| Action | Description |
| :--- | :--- |
| `edit` | Open the specified recipe file in the configured external editor. |
| `help` | Display command-line help for recipe mode. (Default when omitted). |
| `list` | List all available recipes defined in configuration groups. |
| `print` | Display the contents of the specified recipe file with line numbers. |

### Options

| Option | Description |
| :--- | :--- |
| `--config=<name>` | Load a specific configuration file to resolve recipe search paths and editor. |
| `--debug` | Enable verbose debug output. |

### Usage

```bash
# Display help for recipe mode
pods recipe
pods recipe help

# List all available recipes
pods recipe list

# Print a recipe file with line numbers
pods recipe print web-service

# Edit a recipe file using the configured external editor
pods recipe edit web-service

# Print a recipe located in an alternative configuration path
pods --config=staging recipe print web-service
```

---

## Help Mode

The `help` mode prints syntax summaries, available modes, options, and actions directly in the terminal.

```bash
pods help
# or
pods <mode> help
```

### Usage

```bash
# Display general help
pods help

# Display help for config mode
pods config help

# Display help for recipe mode
pods recipe help

# Display help for command mode
pods command help
```

---

## Comprehensive Examples

### Configuration File (`config.lua`)

A complete configuration template demonstrating all available configuration options:

```lua
-- PodScript Configuration
return {
    -- The editor to use for editing files via 'config edit' or 'recipe edit'.
    editor = "vim",

    -- If true, commands will be printed but not executed (dry-run mode).
    simulate = true,

    -- Pod-specific configurations.
    pods = {
        -- The default root directory for all pod-related data.
        path = "/pods",
    },

    -- Defines where to find recipe files for pod creation.
    recipes = {
        -- The default search path for recipe files (defaults to current directory if omitted).
        path = ".",

        -- Defines groups of recipes that can be run together.
        -- All active recipes must belong to at least one group.
        groups = {
            all = {
                "recipe",
            },
            database = {
                "postgres",
                "redis",
            },
            web = {
                "api-server",
                "frontend",
            },
            stack = {
                "@database",
                "@web",
            },
        },
    },
}
```

See [config.lua](config.lua) for the repository configuration template and [recipe.lua](recipe.lua) for the full recipe example.

### Basic Pod Lifecycle

```bash
# Create a pod and its containers from recipe 'nextcloud'
pods create nextcloud

# Update container images to newest versions and restart if updated
pods update nextcloud

# Recreate the entire pod stack (reverse teardown, forward startup)
pods recreate nextcloud

# Stop and remove the pod and all associated containers
pods remove nextcloud
```

### Dry-Run Simulation

Simulation allows you to verify generated Podman commands before making any changes:

```bash
# Simulate creating a pod
pods simulate create nextcloud

# Simulate recreation with verbose debug logging
pods simulate --debug recreate nextcloud

# Simulate maintenance command execution
pods simulate command nextcloud migrate
```

### Recipe Group Targeting

Assuming `config.lua` defines the following groups:

```lua
return {
    recipes = {
        groups = {
            database = { "postgres", "redis" },
            apps     = { "api-service", "frontend" },
            stack    = { "@database", "@apps" },
        },
    },
}
```

```bash
# Deploy all database containers in sequence
pods create @database

# Deploy the entire stack
pods create @stack

# Target both groups and individual recipes (duplicates automatically deduplicated)
pods update postgres @stack frontend
```

### Container Maintenance Tasks

```bash
# Show available maintenance commands for the database recipe
pods command postgres list

# Output:
# Commands for recipe 'postgres':
#   1) backup: Creates a database backup dump.
#   2) reindex: Rebuilds missing search indices.

# Run the backup command by name
pods command postgres backup

# Run the reindex command by numeric index
pods command postgres 2
```

### Configuration Overrides & Debugging

```bash
# Run operations using a dedicated staging configuration
pods --config=staging create @stack

# Inspect the staging configuration
pods --config=staging config print

# Run with verbose debug logging to inspect command construction
pods --debug update web-service
```
