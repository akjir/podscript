---
id: PSP-027
title: Declarative File Seeding
status: concept
type: feature
created: 2026-10-09
updated: 2026-10-13
---

# PSP-027: Declarative File Seeding

## Part 1: Concept & Proposal

### 1.1 Summary
This feature adds declarative file seeding to PodScript recipes. PodScript copies files and directories from the host into containers during initialization using `podman cp` before container start.

### 1.2 Motivation
Mounting static configuration files through host volume bind mounts causes common operational problems:
- **File permissions**: Host files frequently require specific UID and GID values that conflict with container users, especially in rootless mode.
- **SELinux conflicts**: Volume label flags (`:z` or `:Z`) can alter host file contexts unexpectedly.
- **Unintended writes**: Containers can overwrite host configuration files when directories are mounted read-write.
- **Missing directories**: Bind mounts fail if referenced host directories do not exist before container start.

Declarative file seeding solves these problems. PodScript copies configuration files directly into the container filesystem after creation and before start. The container uses its own copy of the files, which prevents permission conflicts on the host system.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Add a `copy` directive to the container configuration schema in recipes.
  * Support copying files and directories from the host into containers.
  * Resolve relative host paths automatically against `recipe.pod.path`.
  * Execute `podman cp` between container creation and container start phases.
  * Support simulation mode (`--simulate`) for all file copy commands.
  * Validate copy configuration during recipe validation.
* **Non-Goals:**
  * Continuously synchronize files between the host and running containers.
  * Copy files from containers back to the host system.
  * Replace volume mounts for large dynamic datasets or persistent database storage.

### 1.4 Description
Users configure a `copy` list inside a container definition in a recipe. Each item defines a source path on the host and a destination path in the container.

When PodScript initializes a container with file seeding:
1. PodScript creates the container in the stopped state using `podman create`.
2. PodScript iterates through the `copy` entries and executes `podman cp <source> <container>:<target>`.
3. PodScript starts the container using `podman start <container>`.

When a container has no `copy` directive defined, PodScript uses the standard `podman run` workflow.

In simulation mode (`--simulate`), PodScript prints each `podman create`, `podman cp`, and `podman start` command without executing them.

### 1.5 Alternatives
* **Host Bind Mounts (`volumes` directive)**:
  Mount files directly using the `--volume` option.
  *Rejected*: Bind mounts cause permission conflicts in rootless containers and risk modifying host files.
* **Custom Container Images**:
  Build specialized images containing the configuration files.
  *Rejected*: Requires external image build pipelines and registries for simple configuration files.
* **Entrypoint Scripts**:
  Embed shell scripts inside containers to download or generate configuration files at runtime.
  *Rejected*: Requires modifying upstream vendor images and adds unnecessary runtime dependencies.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* **`src/pods/recipe.lua`**:
  * Add validation for the `copy` field in container configurations.
  * Validate path types, format, and structure.
* **`src/pods/container.lua`**:
  * Add support for the phased lifecycle (`podman create`, `podman cp`, `podman start`) when `container.copy` is present.
  * Resolve relative host paths against `recipe.pod.path`.
  * Construct and execute safe `podman cp` commands with shell escaping.
* **`recipe.lua`**:
  * Document the `copy` directive with an example in the root template.

### 2.2 Schema & Syntax Changes
Add the optional `copy` array to container definitions in recipes:

```lua
containers = {
    {
        name = "*web",
        image = "nginx:alpine",
        copy = {
            { "./nginx.conf", "/etc/nginx/nginx.conf" },
            { "./conf.d/", "/etc/nginx/conf.d/" },
        },
    },
}
```

Validation rules:
* `copy` must be a sequential array of tables.
* Each entry must contain at least two elements: `{ source_path, target_path }`.
* `source_path` must be a non-empty string.
* `target_path` must be a non-empty string and must be an absolute path inside the container.
* Relative `source_path` values (starting with `./` or not starting with `/`) resolve against `recipe.pod.path`.

### 2.3 Implementation Details
* **Container Lifecycle Separation (`src/pods/container.lua`)**:
  * Inspect `container.copy`:
    * If `table.is_nil_or_empty(container.copy)` is true, execute the standard `podman run` command.
    * If `table.is_nil_or_empty(container.copy)` is false:
      1. Replace `podman run` command with `podman create`.
      2. Execute the `podman create` command.
      3. For each copy entry, construct:
         `podman cp <source> <container_name>:<target>`
      4. Execute each copy command via `system.exec`.
      5. Construct and execute `podman start <container_name>`.
* **Path Resolution**:
  * Use `util.build_full_path(pod.path, host_path, "")` for relative paths.
  * Escape all shell arguments using `string.escape_shell`.
* **Error Handling**:
  * Recipe validation rejects malformed copy tables before command execution.
  * Non-zero return codes from `podman cp` halt container startup.

### 2.4 Testing Strategy
* **Schema Validation Tests (`tests/pods/suite_006_recipes.lua`)**:
  * Verify valid copy entries pass validation.
  * Verify non-table copy entries cause validation failure.
  * Verify missing source or target entries cause validation failure.
* **Command Generation Tests (`tests/pods/suite_008_containers.lua`)**:
  * Verify `podman run` is generated when `copy` is nil or empty.
  * Verify `podman create` is generated when `copy` contains entries.
  * Verify relative source paths resolve against `pod.path`.
  * Verify `podman cp` commands include escaped arguments and correct container names.
  * Verify `podman start` executes after all `podman cp` commands.
  * Verify commands output correctly under `--simulate`.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [ ] Add unit test cases for `copy` validation in `tests/pods/suite_006_recipes.lua`.
- [ ] Add unit test cases for `podman create`, `podman cp`, and `podman start` in `tests/pods/suite_008_containers.lua`.
- [ ] Implement recipe validation logic for `copy` in `src/pods/recipe.lua`.
- [ ] Implement copy resolution and phased lifecycle in `src/pods/container.lua`.
- [ ] Update root `recipe.lua` template with `copy` directive example.
- [ ] Update `USAGE.md` with file seeding documentation and examples.
- [ ] Execute release build (`lua build.lua`).
- [ ] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [ ] Add entry to `CHANGELOG.md`.
- [ ] Set status to `review`, update `BOARD.md`, and request manual user review.

### 3.2 Work Log & Decisions
* **2026-10-09:** Initial concept drafted.
* **2026-10-13:** Rewrote and expanded specification to follow ASD-STE100 rules and completed Parts 1, 2, and 3.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
