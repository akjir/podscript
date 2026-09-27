---
id: PSP-013
title: Systemd / Quadlet Export
status: concept
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-013: Systemd / Quadlet Export

## Part 1: Concept & Proposal

### 1.1 Summary
PodScript excels at lightweight, declarative pod and container management. However, many production environments prefer native `systemd` integration for process supervision, auto-starting on boot, and robust log management. Podman provides Quadlets (`.pod`, `.container`, etc.) to declaratively generate systemd units. This proposal bridges the gap by allowing users to export their PodScript recipes directly into Podman Quadlet format via a separate, on-demand tool/module called `pods-generate`.

### 1.2 Motivation
Currently, users of PodScript have to manually translate their simple Lua configuration into Quadlet files if they want systemd's robust process management. By natively generating Quadlet configurations via a supplementary tool, users get the best of both worlds: PodScript's simple Lua configuration and systemd's robust process management, without bloating the core `pods` executable.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Introduce a new CLI tool/module `pods-generate` (or invoked via `pods generate`) to translate recipes into Quadlet files.
  * Map PodScript directives (`publish`, `volumes`, `commands`, `options`, `restart`) to their exact Quadlet equivalents (`PublishPort`, `Volume`, `Exec`, `PodmanArgs`, `Restart`).
  * Ensure output files are safely written to `<pod.path>/systemd/`.
  * Maintain zero external dependencies and strict Lua 5.5 rules.
* **Non-Goals:**
  * Automatic installation or enabling of Quadlets into `/etc/containers/systemd/` or `~/.config/containers/systemd/`. The user is responsible for copying or symlinking the generated files.
  * Live lifecycle management (e.g., `systemctl start`) through PodScript. PodScript will continue to use `podman run` for its own `create`/`remove` actions.

### 1.4 Description
* **Command Syntax:**
  ```bash
  pods generate systemd <recipe> [targets...]
  # or directly calling the module:
  lua pods-generate.lua systemd <recipe> [targets...]
  ```
* **Output:**
  For a recipe named `web-service`, defining a pod `web-stack` and containers `app` and `db`, the command will generate:
  * `<pod.path>/systemd/web-stack.pod`
  * `<pod.path>/systemd/web-stack-app.container`
  * `<pod.path>/systemd/web-stack-db.container`

### 1.5 Alternatives
* Manually writing Quadlet files (error-prone and duplicates configuration).
* Third-party templating tools (violates the zero external dependencies goal).

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* **New Tool/Module (`src/pods-generate/`):**
  * A dedicated source directory and module responsible for handling the CLI generation logic and transforming the `recipe` table into Quadlet `.ini` string representations.
  * Will be built into a separate `pods-generate.lua` artifact, not shipped within the normal `pods` artifact, as its use case goes beyond the direct control of Podman.
* **Changes to `main.lua` / `USAGE.md`:**
  * If invoked as `pods generate`, the main script will check for the existence of `pods-generate.lua` in its directory and delegate execution, failing gracefully if not present.

### 2.2 Schema & Syntax Changes
No breaking schema changes. The `pods-generate` tool is purely additive.

### 2.3 Implementation Details
* **`src/pods-generate/quadlet.lua`:**
  * Implements `quadlet__generate_pod(recipe)` and `quadlet__generate_container(container, pod_name)`.
  * Follows `global<const> *` and uses string interpolation/concatenation efficiently.
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
* **`src/pods-generate/main.lua`:**
  * Uses recipe loading and validation, then writes output files to `<pod.path>/systemd/`.

### 2.4 Testing Strategy
* **Unit Tests (`tests/pods-generate/test_quadlet.lua`):**
  * Assert mapping of all recipe combinations (with/without options, publish ports, volumes, commands).
  * Assert correct handling of empty/nil fields.
* **Mode Tests (`tests/pods-generate/test_main.lua`):**
  * Assert `pods-generate systemd <recipe>` correctly parses arguments.
  * Assert files are physically written to the expected `<pod.path>/systemd/` mock directory.
* **Edge Cases:**
  * Recipes without a `pod.path` fallback logic.
  * Containers with commands containing spaces (must be properly shell-escaped or quoted for `Exec=`).

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Update build logic to output `pods-generate.lua`.
- [ ] Create test stubs in `tests/pods-generate/test_main.lua` and `tests/pods-generate/test_quadlet.lua`.
- [ ] Implement core logic in `src/pods-generate/quadlet.lua`.
- [ ] Implement CLI handling in `src/pods-generate/main.lua`.
- [ ] Update core `pods` to delegate `generate` commands to `pods-generate.lua`.
- [ ] Add entry to `CHANGELOG.md`.
- [ ] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [ ] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-09-26:** Initial concept and specification written. Decided against auto-installing Quadlets to maintain PodScript's role as a standalone, non-intrusive tool.
* **2026-09-26:** Architecture updated to use a separate `pods-generate` module instead of baking generation into the core `pods` script.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
