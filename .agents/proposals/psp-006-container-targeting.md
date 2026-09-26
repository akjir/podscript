---
id: PSP-006
title: Granular Container Targeting within Pods (recipe/container)
status: concept
type: feature
created: 2026-09-25
updated: 2026-09-26
---

# PSP-006: Granular Container Targeting within Pods (`recipe/container`)

## Part 1: Concept & Proposal (JEP-Style)

### 1.1 Summary
Enable actions (`create`, `recreate`, `update`, `remove`) targeting an individual container using the `recipe/container` syntax without recreating the entire parent pod.

### 1.2 Motivation
In multi-container pods (e.g. `web` + `redis` + `db`), updating or restarting a single service (such as releasing a new version of `web`) currently recreates or restarts the entire pod, terminating all sibling containers and resetting the shared network namespace. Enabling targeted single-container lifecycle actions reduces downtime and accelerates developer workflows.

### 1.3 Goals & Non-Goals
* **Goals:**
    * Enable actions (`create`, `recreate`, `update`, `remove`) targeting an individual container using `recipe/container` syntax.
    * Automatically verify if the parent pod exists:
        * Create the parent pod first if missing before creating/starting the container.
        * Attach to the existing pod if already running.
    * For `remove`: Delete only the specified container, leaving the parent pod and sibling containers intact.
* **Non-Goals:**
    * Supporting ambiguous shell delimiters like `#` (which trigger comments in bash/zsh).
    * Recreating sibling containers during a single-container update.

### 1.4 Description
Users will be able to target specific containers within a pod using the `recipe/container` syntax for CLI actions. The following actions will be supported: `pods create mypod/app`, `pods update mypod/app`, `pods remove mypod/app`, `pods recreate mypod/app`.

Lifecycle Rules:
* **`create` / `recreate`:**
    * Pre-check: `podman pod exists <pod_name>`.
    * If pod missing: Execute `podman pod create ...` with all recipe pod publish/option settings, then run the specified container.
    * If pod exists: Run only the specified container attached to the pod (`podman run --pod <pod_name> ...`).
* **`update`:**
    * Pull image for the targeted container only (`podman pull ...`).
    * Stop & remove only the targeted container (`podman rm -f <container_name>`).
    * Recreate that container inside the existing pod.
* **`remove`:**
    * Stop & remove only the targeted container (`podman rm -f <container_name>`).
    * The parent pod and other containers remain untouched.

### 1.5 Alternatives
Evaluated using `#` vs `/` vs `--container` for the syntax. Selected `recipe/container` and discarded `#` because it triggers comments in bash/zsh, and `--container` as it is more verbose.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/utilities.lua`
* `src/pods/system.lua`
* `src/pods/pod.lua`
* `src/pods/mode_default.lua`

### 2.2 Schema & Syntax Changes
* **Syntax:** Addition of `recipe/container` syntax for targeting individual containers on the CLI. No underlying configuration schema changes are required.

### 2.3 Implementation Details
* **Target Parsing (`utilities.lua`):**
    * Parse target string for `/` delimiter separating recipe name and container name.
    * `parse_recipe_and_container(target)` -> returns `recipe_name`, `container_name`.
* **Pod & Container Helpers (`system.lua`):**
    * Add `system.pod_exists(name)` executing `podman pod exists <name>`.
    * Add `system.container_exists(name)` executing `podman container exists <name>`.
* **Pod Dispatch Updates (`pod.lua` / `mode_default.lua`):**
    * Support optional `target_container` filter in `pod__create`, `pod__remove`, `pod__update`.
    * Use existence helpers to execute conditional pod creation before container start.

### 2.4 Testing Strategy
* Test target parser for `recipe` vs `recipe/container`.
* Test `create` with pod non-existent (creates pod + container).
* Test `create` with pod already existing (creates container only).
* Test `remove` with container only (pod remains).
* Add test suite to `tests/pods/suite_005_targets.lua` and `tests/pods/suite_007_pods.lua`.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Create test stubs in `tests/pods/suite_005_targets.lua` and `tests/pods/suite_007_pods.lua`.
- [ ] Implement `parse_recipe_and_container` in `src/pods/utilities.lua`.
- [ ] Implement `system.pod_exists` and `system.container_exists` in `src/pods/system.lua`.
- [ ] Update optional container targeting in `src/pods/pod.lua` and `src/pods/mode_default.lua`.
- [ ] Update `USAGE.md` with new CLI syntax.
- [ ] Add entry to `CHANGELOG.md`.

### 3.2 Work Log & Decisions
* **2026-09-25:** Initial concept documented; evaluated `#` vs `/` vs `--container`. Selected `recipe/container` and discarded other syntaxes.
* **2026-09-26:** Migrated to `.agents/features/psp-006-container-targeting.md`.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
