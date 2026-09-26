---
id: PSP-012
title: Podman Network & Named Volume Management
status: planned
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-012: Podman Network & Named Volume Management

## 1. Summary & Motivation
PodScript currently manages pods and containers, but relies on externally created networks and volumes, or automatically created default ones. To achieve fully declarative, self-contained recipes, PodScript needs the ability to define and auto-provision required Podman networks and named volumes before a pod is started.

## 2. Goals & Non-Goals
* **Goals:**
  * Allow defining required networks and volumes directly in the recipe file.
  * Auto-create these networks and volumes before pod/container creation using `podman network create --ignore` and `podman volume create --ignore`.
  * Support simple name definitions as well as advanced configurations (labels, drivers, options).
* **Non-Goals:**
  * Pruning or deleting networks/volumes automatically on pod removal (networks and volumes may be shared across multiple pods).
  * Migrating existing data in volumes.

## 3. Specification & CLI Syntax
* **Recipe Schema Additions:**
  Top-level `networks` and `volumes` tables are added to the recipe schema.
  
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

* **CLI Syntax & Output Behavior:**
  * No new modes or CLI flags.
  * During `create`, `update` (if recreating), and `recreate` actions, PodScript will iterate through `networks` and `volumes` and execute the respective `podman network create --ignore` and `podman volume create --ignore` commands.
  * Logs will output `[CREATE] Network: frontend-net` or `[CREATE] Volume: db-data`.
  * `simulate` mode will print these commands.

## 4. Technical Architecture
* **Affected Files:**
  * `src/pods/recipe.lua`: Update recipe parsing to validate and extract `networks` and `volumes` definitions.
  * `src/pods/pod.lua` or a new `src/pods/infrastructure.lua`: Add logic to generate and execute `podman network create` and `podman volume create` commands.
  * `src/pods/mode_default.lua`: Integrate the network/volume creation step immediately before `pod__create(...)` is called.
* **Strict Lua 5.5 & Rules:**
  * Use `global<const> *` at the top of any new files.
  * Avoid global variables.
  * Generate `podman` commands by safely shell-escaping names and options.
* **Command Generation:**
  * `podman network create --ignore [OPTIONS] NAME`
  * `podman volume create --ignore [OPTIONS] NAME`

## 5. Test Strategy (TDD)
* **Code Tests:** 
  * Parse complex `networks` and `volumes` definitions (mixed strings and tables).
  * Validate command generation accurately maps Lua table fields (`label`, `opt`, `internal`) to Podman flags (`--label`, `--opt`, `--internal`).
* **Mode Tests:**
  * Run `pods simulate create` on a recipe with networks and volumes and assert the `podman network create` and `podman volume create` commands appear before the pod creation commands.
* **Edge Cases:**
  * Empty tables or omitted `networks`/`volumes` fields.
  * Invalid types in tables.

## 6. Work Log & Decisions
* **2026-09-26:** Specification planned and drafted. Added support for both simple string names and detailed configuration tables. Chose not to auto-delete networks/volumes on removal to avoid destroying shared resources.
