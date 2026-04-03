# Usage

PodScript uses a mode-driven command structure. The general syntax is:

```bash
lua pods.lua [MODE] [OPTIONS] [ACTION] [TARGETS]
```

Or, if you have the helper script installed:

```bash
pods [MODE] [OPTIONS] [ACTION] [TARGETS]
```

## Modes

Modes determine the primary behavior of the script. If no mode is specified, PodScript runs in the **Default Mode**.

| Mode | Description |
| :--- | :--- |
| `(empty)` | **Default Mode**: Executes actions as defined in the recipes. |
| `simulate` | **Simulate Mode**: Previews all commands without actually executing them. Useful for verifying changes. |
| `config` | **Config Mode**: Manages and displays the current configuration. |
| `recipe` | **Recipe Mode**: Inspects a specific recipe. |
| `help` | **Help Mode**: Displays the built-in help message and exits. |

---

## Default & Simulate Modes

These modes are used to manage pods and containers. They require an **Action** and one or more **Targets**.

### Actions

| Action | Description |
| :--- | :--- |
| `create` | Create a new pod and its containers as defined in the target recipe(s). |
| `recreate` | Stop and remove an existing pod and its containers, then create them anew. |
| `remove` | Stop and remove a running pod and all its containers. |
| `update` | Pull the latest versions of the container images defined in the pod recipe and restart the containers if needed. |

### Options

| Option | Description |
| :--- | :--- |
| `--config <name>`| Use a specific configuration file (e.g., `--config alternative_config`). |
| `--debug` | Enable verbose debug output for troubleshooting. |

### Targets

Targets specify which recipes or groups of recipes the action should be applied to.

*   `<recipe_name>`: The name of a specific recipe file (without the `.lua` extension).
*   `@<group_name>`: The name of a recipe group defined in your configuration file.

#### Execution Order and Recipe Groups

Recipes can be declared in multiple groups. When multiple groups or individual recipes are specified as targets, their overall execution order is determined by their **first appearance** in the target list.

**Key points:**

*   **Order Matters:** The order of recipes within a group is significant; recipes are executed in the sequence they are listed.
*   **First Appearance Rule:** If a recipe is mentioned multiple times (either directly or through multiple groups), only its first occurrence in the target list determines its execution position in all actions.

### Usage

```bash
lua pods.lua create my-pod
```

---

## Help Mode

The `help` mode provides a quick reference for commands and options directly in the terminal.

### Usage

```bash
lua pods.lua help
```

You can also combine it with other modes to see context-specific help (if available):

```bash
lua pods.lua simulate help
```

---

## Config Mode

The `config` mode allows you to inspect the active configuration.

### Actions

| Action | Description |
| :--- | :--- |
| `print` | Display the content of the current configuration file with line numbers. |
| `help` | Display help for the config mode. |

### Usage

1.  **Print the default configuration:**
    ```bash
    lua pods.lua config print
    ```
2.  **Print a specific configuration:**
    ```bash
    lua pods.lua --config alternative_config config print
    ```

---

## Recipe Mode

The `recipe` mode allows you to inspect a specific recipe.

### Actions

| Action | Description |
| :--- | :--- |
| `print` | Display the content of a specific recipe file with line numbers. |
| `help` | Display help for the recipe mode. |

### Usage

1.  **Print a specific recipe:**
    ```bash
    lua pods.lua recipe print my-recipe
    ```
2.  **Print a recipe using a specific configuration:**
    ```bash
    lua pods.lua --config alternative_config recipe print my-recipe
    ```

---

## Examples

### Basic Usage (Default Mode)

1.  **Create a pod from a recipe:**
    ```bash
    lua pods.lua create my-web-server
    ```
2.  **Remove a pod:**
    ```bash
    lua pods.lua remove my-web-server
    ```
3.  **Recreate a group of pods:**
    ```bash
    lua pods.lua recreate @production-apps
    ```

### Simulation

1.  **Simulate creating a pod to see what commands would run:**
    ```bash
    lua pods.lua simulate create my-web-server
    ```
2.  **Simulate removing a group of pods:**
    ```bash
    lua pods.lua simulate remove @staging-apps
    ```

### Using Options

1.  **Use a specific configuration file:**
    ```bash
    lua pods.lua --config my_custom_config create my-web-server
    ```
2.  **Enable debug logging during an update:**
    ```bash
    lua pods.lua --debug update my-web-server
    ```
3.  **Combine options and modes:**
    ```bash
    lua pods.lua simulate --debug --config alt_config recreate @test-group
    ```

### Advanced Targeting

1.  **Mixing recipes and groups:**
    If `@glados` is defined as `{ "the", "cake", "lie" }`, then:
    ```bash
    lua pods.lua create the @glados lie
    ```
    *Execution order:* `the`, `cake`, `lie`.

2.  **Respecting first appearance:**
    ```bash
    lua pods.lua create lie cake @glados
    ```
    *Execution order:* `lie`, `cake`, `the`. (Since `lie` and `cake` appeared first, they are not repeated when `@glados` is expanded).
