---
id: PSP-008
title: Health-Aware Lifecycle Ordering
status: concept
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-008: Health-Aware Lifecycle Ordering

## Part 1: Concept & Proposal (JEP-Style)

### 1.1 Summary
This feature introduces health-aware lifecycle ordering, allowing PodScript to pause and wait for a container to become `healthy` (utilizing Podman's native healthchecks) before proceeding to the next container in the recipe.

### 1.2 Motivation
When starting multiple containers via a PodScript recipe, it is often critical to ensure that a foundational container (e.g., a database) is fully operational before starting its dependents. Currently, PodScript starts containers sequentially without verifying their operational state. This eliminates race conditions in complex multi-container setups and improves overall reliability.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Support declarative waiting for container states within PodScript recipes.
  * Utilize `podman wait` to block recipe execution until a container reaches a desired condition (e.g., `healthy`).
  * Fail fast and abort the recipe if a container becomes `unhealthy` or exits prematurely.
  * Maintain zero external dependencies, relying entirely on standard Podman functionality.
* **Non-Goals:**
  * Implementing custom health-checking logic or HTTP probes within PodScript (delegated to Podman).
  * Waiting on arbitrary log output patterns.
  * Complex dependency graph resolution (containers are still started in the exact order they are listed in the recipe array).

### 1.4 Description
* **CLI Syntax:**
  * Command syntax remains unchanged (e.g., `pods recipe up <file>`).
  * If a `wait_condition` is set, `pods recipe up` will emit an info log: `Waiting for container <name> to reach condition: <condition>...`
* **Exit Codes:**
  * If the wait condition is not met (e.g., the container becomes `unhealthy` or exits instead of becoming `healthy`), PodScript logs a failure message and exits with a non-zero exit code (e.g., `1`), halting further recipe execution.

### 1.5 Alternatives
* **Bash Scripts & Timers:** Adding a `sleep` command in recipes or waiting for ports via external scripts (e.g., `nc` or `curl`). These are rejected because they introduce external dependencies and are less declarative than Podman's native healthcheck and wait mechanisms.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* **`src/pods/recipe.lua`**: Update schema validation to recognize the `wait_condition` property.
* **`src/pods/container.lua`**: Add a new modular function `global function container__wait_for_condition(name, condition)` to handle the blocking wait.
* **`src/pods/mode_recipe.lua`**: Modify the startup loop in `mode_recipe__up`. After starting a container, check if `wait_condition` is specified. If so, invoke `container__wait_for_condition`.

### 2.2 Schema & Syntax Changes
* Introduce a `wait_condition` field (string type) within the container definition in the recipe format.
* Example usage in a Lua recipe:
  ```lua
  containers = {
      {
          name = "db",
          image = "postgres:15",
          healthcheck = {
              test = {"CMD-SHELL", "pg_isready -U postgres"},
              interval = "5s",
              retries = 5,
          },
          wait_condition = "healthy",
      },
      {
          name = "backend",
          image = "my-backend",
          -- PodScript will only start this after 'db' is healthy
      }
  }
  ```

### 2.3 Implementation Details
* **Podman Commands:**
  * Core mechanism uses:
    `podman wait --condition=<condition> --condition=unhealthy --condition=exited --exit-first-match <container_name>`
  * Using `--exit-first-match` along with failure conditions (`unhealthy`, `exited`) ensures PodScript does not hang indefinitely if the container fails to start or fails its healthcheck.
  * PodScript will parse the exit code or use `podman inspect` afterward to confirm if the *desired* condition was met, failing the recipe otherwise.
* **Strict Lua 5.5 Rules:**
  * Must adhere to `global<const> *` at the top of the modified chunks.
  * Proper error propagation without silent failures.

### 2.4 Testing Strategy
* **Required Test Suites:**
  * `tests/pods/test_mode_recipe.lua`: Add a fixture with a `wait_condition` and verify that the startup sequence calls `podman wait` with the correct flags before moving to the next container.
  * `tests/pods/test_container.lua`: Unit test `container__wait_for_condition` handling various scenarios: successfully reaching `healthy`, failing by reaching `unhealthy`, and exiting immediately.
* **Edge Cases & Failure Modes:**
  * Missing healthcheck definition in the container but `wait_condition = "healthy"` is specified.
  * Handling containers that exit with `0` (success) but were expected to be `healthy`.
  * Standard behavior under rootless vs. elevated execution (should be transparent as Podman handles the healthchecks).

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Create test stubs in `tests/pods/test_container.lua` and `tests/pods/test_mode_recipe.lua`.
- [ ] Implement schema validation in `src/pods/recipe.lua`.
- [ ] Implement `container__wait_for_condition` in `src/pods/container.lua`.
- [ ] Integrate wait logic in `src/pods/mode_recipe.lua` (`mode_recipe__up`).
- [ ] Update `USAGE.md` with new `wait_condition` documentation.
- [ ] Add entry to `CHANGELOG.md`.

### 3.2 Work Log & Decisions
* **2026-09-26:** Initial concept created (PSP-008). Decided to leverage `podman wait --exit-first-match` with multiple conditions (`unhealthy`, `exited`) to handle timeouts and failures natively without manual Lua timers.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
