---
id: PSP-012
title: Podman Network & Named Volume Management
status: planned
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-012: Podman Network & Named Volume Management

## Part 1: Concept & Proposal (JEP-Style)

### 1.1 Summary
PodScript will support defining and auto-provisioning required Podman networks and named volumes directly within recipes, before a pod is started, enabling fully declarative and self-contained deployments.

### 1.2 Motivation
PodScript currently manages pods and containers but relies on externally created networks and volumes or automatically created default ones. To achieve fully declarative, self-contained recipes where a single file describes the entire environment, PodScript needs the native ability to define and auto-provision required Podman networks and named volumes.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Allow defining required networks and volumes directly in the recipe file.
  * Auto-create these networks and volumes before pod/container creation using `podman network create --ignore` and `podman volume create --ignore`.
  * Support simple name definitions as well as advanced configurations (labels, drivers, options).
* **Non-Goals:**
  * Pruning or deleting networks/volumes automatically on pod removal (networks and volumes may be shared across multiple pods).
  * Migrating existing data in volumes.

### 1.4 Description
Users will be able to define required networks and volumes within the recipe structure. During `create`, `update` (if recreating), and `recreate` actions, PodScript will iterate through these `networks` and `volumes` definitions and execute the respective `podman network create --ignore` and `podman volume create --ignore` commands. 
Logs will output `[CREATE] Network: <name>` or `[CREATE] Volume: <name>`. `simulate` mode will print these commands without executing them. No new CLI flags or modes are required.

### 1.5 Alternatives
* **External Shell Scripts:** Relying on external setup scripts to provision networks and volumes before invoking PodScript. This was rejected because it violates the goal of having fully declarative, self-contained recipes managed by a single tool.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/recipe.lua`: Update recipe parsing to validate and extract `networks` and `volumes` definitions.
* `src/pods/pod.lua` or a new `src/pods/infrastructure.lua`: Add logic to generate and execute `podman network create` and `podman volume create` commands.
* `src/pods/mode_default.lua`: Integrate the network/volume creation step immediately before `pod__create(...)` is called.

### 2.2 Schema & Syntax Changes
Top-level `networks` and `volumes` tables will be added to the recipe schema:

```lua
return {
    name = "My App",
    networks = {
        "frontend-net", -- simple string for default bridge network
        {
            name = "backend-net",
            internal = true,
            label = { "env=prod" }
        }
    },
    volumes = {
        "db-data", -- simple string for default local volume
        {
            name = "app-logs",
            driver = "local",
            opt = { "type=tmpfs", "device=tmpfs", "o=size=100m,uid=1000" }
        }
    },
    pod = { ... },
    containers = { ... }
}
```

### 2.3 Implementation Details
* **Strict Lua 5.5 & Rules:**
  * Use `global<const> *` at the top of any new files.
  * Avoid global variables.
  * Generate `podman` commands by safely shell-escaping names and options.
* **Command Generation:**
  * `podman network create --ignore [OPTIONS] NAME`
  * `podman volume create --ignore [OPTIONS] NAME`
* Configuration tables will need to be parsed to map Lua fields (like `label`, `opt`, `internal`, `driver`) to their corresponding Podman CLI flags (e.g., `--label`, `--opt`, `--internal`, `--driver`).

### 2.4 Testing Strategy
* **Code Tests:** 
  * Parse complex `networks` and `volumes` definitions (mixed strings and tables).
  * Validate command generation accurately maps Lua table fields to Podman flags.
* **Mode Tests:**
  * Run `pods simulate create` on a recipe with networks and volumes and assert the `podman network create` and `podman volume create` commands appear before the pod creation commands.
* **Edge Cases:**
  * Empty tables or omitted `networks`/`volumes` fields.
  * Invalid types in tables.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Update recipe schema and validation in `src/pods/recipe.lua`.
- [ ] Add command generation logic for networks and volumes in `src/pods/pod.lua` or `infrastructure.lua`.
- [ ] Integrate creation steps into `src/pods/mode_default.lua` before pod creation.
- [ ] Create unit tests for parsing and command generation.
- [ ] Create integration/mode tests for `simulate` and `create` workflows.
- [ ] Update documentation with the new recipe schema examples.
- [ ] Add entry to `CHANGELOG.md`.

### 3.2 Work Log & Decisions
* **2026-09-26:** Specification planned and drafted. Added support for both simple string names and detailed configuration tables. Chose not to auto-delete networks/volumes on removal to avoid destroying shared resources.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
