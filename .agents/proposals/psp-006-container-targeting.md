---
id: PSP-006
title: Granular Container Targeting within Pods (recipe/container)
status: concept
type: feature
created: 2026-09-25
updated: 2026-09-26
---

# PSP-006: Granular Container Targeting within Pods (`recipe/container`)

## 1. Summary & Motivation
In multi-container pods (e.g. `web` + `redis` + `db`), updating or restarting a single service (such as releasing a new version of `web`) currently recreates or restarts the entire pod, terminating all sibling containers and resetting the shared network namespace. Enabling targeted single-container lifecycle actions reduces downtime and accelerates developer workflows.

## 2. Goals & Non-Goals
* **Goals:**
    * Enable actions (`create`, `recreate`, `update`, `remove`) targeting an individual container using `recipe/container` syntax.
    * Automatically verify if the parent pod exists:
        * Create the parent pod first if missing before creating/starting the container.
        * Attach to the existing pod if already running.
    * For `remove`: Delete only the specified container, leaving the parent pod and sibling containers intact.
* **Non-Goals:**
    * Supporting ambiguous shell delimiters like `#` (which trigger comments in bash/zsh).
    * Recreating sibling containers during a single-container update.

## 3. Specification & CLI Syntax
* **Syntax:** `recipe/container`
    * `pods create mypod/app`
    * `pods update mypod/app`
    * `pods remove mypod/app`
    * `pods recreate mypod/app`
* **Lifecycle Rules:**
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

## 4. Technical Architecture
* **Target Parsing (`utilities.lua`):**
    * Parse target string for `/` delimiter separating recipe name and container name.
    * `parse_recipe_and_container(target)` -> returns `recipe_name, container_name`.
* **Pod & Container Helpers (`system.lua`):**
    * `system.pod_exists(name)` executing `podman pod exists <name>`.
    * `system.container_exists(name)` executing `podman container exists <name>`.
* **Pod Dispatch Updates (`pod.lua` / `mode_default.lua`):**
    * Support optional `target_container` filter in `pod__create`, `pod__remove`, `pod__update`.
* **Affected Files:**
    * `src/pods/utilities.lua`
    * `src/pods/system.lua`
    * `src/pods/pod.lua`
    * `src/pods/mode_default.lua`

## 5. Test Strategy (TDD)
* Test target parser for `recipe` vs `recipe/container`.
* Test `create` with pod non-existent (creates pod + container).
* Test `create` with pod already existing (creates container only).
* Test `remove` with container only (pod remains).
* Add test suite to `tests/pods/suite_005_targets.lua` and `tests/pods/suite_007_pods.lua`.

## 6. Work Log & Decisions
* **2026-09-25:** Initial concept documented; evaluated `#` vs `/` vs `--container`. Selected `recipe/container` and discarded other syntaxes.
* **2026-09-26:** Migrated to `.agents/features/psp-006-container-targeting.md`.
