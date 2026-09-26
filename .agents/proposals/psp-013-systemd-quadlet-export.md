---
id: PSP-013
title: Systemd / Quadlet Export
status: concept
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-013: Systemd / Quadlet Export

## 1. Summary & Motivation
PodScript excels at lightweight, declarative pod and container management. However, many production environments prefer native `systemd` integration for process supervision, auto-starting on boot, and robust log management. Podman provides Quadlets (`.pod`, `.container`, etc.) to declaratively generate systemd units. This feature bridges the gap by allowing users to export their PodScript recipes directly into Podman Quadlet format, giving them the best of both worlds: PodScript's simple Lua configuration and systemd's robust process management.

## 2. Goals & Non-Goals
* **Goals:**
  * Introduce a new CLI command `pods generate systemd <targets>` to translate recipes into Quadlet files.
  * Map PodScript directives (`publish`, `volumes`, `commands`, `options`, `restart`) to their exact Quadlet equivalents (`PublishPort`, `Volume`, `Exec`, `PodmanArgs`, `Restart`).
  * Ensure output files are safely written to `<pod.path>/systemd/`.
  * Maintain zero external dependencies and strict Lua 5.5 rules.
* **Non-Goals:**
  * Automatic installation or enabling of Quadlets into `/etc/containers/systemd/` or `~/.config/containers/systemd/`. The user is responsible for copying or symlinking the generated files.
  * Live lifecycle management (e.g., `systemctl start`) through PodScript. PodScript will continue to use `podman run` for its own `create`/`remove` actions.

## 3. Specification & CLI Syntax
* **Command Syntax:**
  ```bash
  pods generate systemd <recipe> [targets...]
  ```
* **Output:**
  For a recipe named `web-service`, defining a pod `web-stack` and containers `app` and `db`, the command will generate:
  * `<pod.path>/systemd/web-stack.pod`
  * `<pod.path>/systemd/web-stack-app.container`
  * `<pod.path>/systemd/web-stack-db.container`

* **Mapping Rules:**
  * **`.pod` File (`web-stack.pod`):**
    * `[Pod]`
    * `PodName=<recipe.pod.name>`
    * `PublishPort=<mapped from recipe.pod.publish>`
    * `PodmanArgs=<mapped from recipe.pod.options>`
  * **`.container` File (`web-stack-app.container`):**
    * `[Unit]`
    * `Description=PodScript generated container for <container.name>`
    * `After=<recipe.pod.name>.pod` (to ensure pod starts first)
    * `[Container]`
    * `Pod=<recipe.pod.name>.pod`
    * `ContainerName=<container.name>`
    * `Image=<registry>/<image>`
    * `Volume=<mapped from container.volumes>`
    * `Exec=<mapped from container.commands>` (Space-separated string of commands)
    * `PodmanArgs=<mapped from container.options>`
    * `[Service]`
    * `Restart=<container.restart>` (e.g. `always`, `on-failure`)
    * `[Install]`
    * `WantedBy=default.target`

## 4. Technical Architecture
* **New Module (`src/pods-converter/quadlet.lua`):**
  * A dedicated module responsible for transforming the `recipe` table into Quadlet `.ini` string representations.
  * Implements `quadlet__generate_pod(recipe)` and `quadlet__generate_container(container, pod_name)`.
  * Follows `global<const> *` and uses string interpolation/concatenation efficiently.
* **New Mode (`src/pods/mode_generate.lua`):**
  * Handles the `generate` CLI mode.
  * Accepts `systemd` as an action.
  * Uses `recipe__load` and `recipe__validate`, then writes output files to `<pod.path>/systemd/`.
* **Changes to `main.lua` / `USAGE.md`:**
  * Register the `generate` mode.

## 5. Test Strategy (TDD)
* **Unit Tests (`tests/pods-converter/test_quadlet.lua`):**
  * Assert mapping of all recipe combinations (with/without options, publish ports, volumes, commands).
  * Assert correct handling of empty/nil fields.
* **Mode Tests (`tests/pods/test_mode_generate.lua`):**
  * Assert `pods generate systemd <recipe>` correctly parses arguments.
  * Assert files are physically written to the expected `<pod.path>/systemd/` mock directory.
* **Edge Cases:**
  * Recipes without a `pod.path` fallback logic.
  * Containers with commands containing spaces (must be properly shell-escaped or quoted for `Exec=`).

## 6. Work Log & Decisions
* **2026-09-26:** Initial concept and specification written. Decided against auto-installing Quadlets to maintain PodScript's role as a standalone, non-intrusive tool.
