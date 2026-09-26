---
id: PSP-011
title: Pre/Post Execution Hooks
status: concept
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-011: Pre/Post Execution Hooks

## Part 1: Concept & Proposal (JEP-Style)

### 1.1 Summary
This feature introduces a hook system allowing PodScript recipes to define shell commands or Lua callbacks tied to lifecycle events like `pre_create`, `post_create`, `pre_remove`, etc., at both the pod and container levels.

### 1.2 Motivation
Users frequently need to perform setup and teardown tasks before or after pod/container lifecycles. Examples include database migrations, directory creation, network configuration, or notifying external systems. Without built-in hooks, users must rely on external wrapper scripts, which breaks the declarative, self-contained nature of PodScript recipes.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Support Lua callbacks and shell commands (strings or arrays).
  * Provide hooks for major lifecycle events: `pre_create`, `post_create`, `pre_start`, `post_start`, `pre_stop`, `post_stop`, `pre_remove`, `post_remove`.
  * Ensure safe execution using `pcall` for Lua callbacks and robust execution for shell commands.
  * Stop/abort the lifecycle operation if a `pre_` hook fails (non-zero exit or Lua error).
* **Non-Goals:**
  * Interactive prompts during hooks.
  * Long-running daemon hooks (all hooks must be synchronous and terminate).

### 1.4 Description
Recipes and individual container definitions will be able to include a `hooks` table. When PodScript executes lifecycle actions (like creating or starting a pod/container), it will check for corresponding `pre_` and `post_` hooks. 
Hooks can be defined as Lua functions, string shell commands, or arrays of command arguments. If a `pre_` hook fails, the associated action is skipped and the CLI aborts with a non-zero exit code.

### 1.5 Alternatives
* **External wrapper scripts:** Users could write bash scripts that run setup commands and then call PodScript. *Rejected* because it forces users to maintain external dependencies and scripts, violating PodScript's goal of being a unified, lightweight declarative manager.
* **Systemd dependencies:** For advanced users, systemd services can handle pre/post execution. *Rejected* as it ties the recipes too closely to systemd and isn't portable or self-contained within the PodScript recipe.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* **`src/pods/recipe.lua`**: Requires updates to schema validation for both recipes and containers.
* **`src/pods/hook.lua`**: A new module responsible for hook parsing and safe execution.
* **`src/pods/pod.lua` & `src/pods/container.lua`**: Need to be updated to integrate lifecycle hooks around existing Podman execution blocks (e.g., `podman pod create`, `podman run`).

### 2.2 Schema & Syntax Changes
Recipes and individual container definitions can include a `hooks` table. The schema will allow functions, strings, and tables for these hook keys.

```lua
return {
    name = "myapp",
    hooks = {
        pre_create = function(context)
            -- Lua callback
            local sys = require("pods.system")
            sys.execute("mkdir -p /data/myapp")
            return true
        end,
        post_create = "echo 'App created'",
        pre_remove = { "rm", "-rf", "/data/myapp/cache" }
    },
    containers = {
        web = {
            image = "nginx:latest",
            hooks = {
                post_start = "curl -f http://localhost:8080/health || exit 1"
            }
        }
    }
}
```

### 2.3 Implementation Details
* **New Module (`src/pods/hook.lua`)**: 
  * Expose `hook__run(hook_definition, context)`.
  * Internal dispatch logic to distinguish between `type(hook) == "function"`, `"string"`, and `"table"`.
  * Use `pcall` to safely invoke Lua functions. Lua callbacks must return `true` or `nil` on success. Returning `false` or throwing an error via `error()` fails the hook.
  * Delegate to `system.*` (e.g., `system.execute`) for shell command execution.
  * For table inputs (command arrays), elements are automatically shell-escaped to prevent injection, then executed.
* **Lifecycle Integration**:
  * Insert `hook__run` calls around existing Podman execution blocks.
  * Handle hook failures cleanly by bubbling up errors via `log.error` and aborting the sequence. For a `pre_` hook failure, the associated action (e.g. creation, start) is skipped and the CLI aborts.
* **Strict Globals & Lua 5.5**: Ensure the new hook system complies with `global<const> *` restrictions.

### 2.4 Testing Strategy
* **Hook Execution Logic (`tests/pods/test_hook.lua`)**:
  * Test Lua callbacks (success, explicit failure via `error()`, return false).
  * Test shell command execution (string format and array formats with escaping).
* **Lifecycle Integration (`tests/pods/test_pod.lua` / `tests/pods/test_container.lua`)**:
  * Verify `pre_create` failure prevents pod/container creation.
  * Verify `post_create` executes only if the creation command succeeds.
* **Failure Modes**:
  * Ensure environment remains clean, errors are cleanly bubbled up to the CLI, and exit codes accurately reflect hook failures.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Create test stubs in `tests/pods/test_hook.lua`.
- [ ] Implement core logic in `src/pods/hook.lua`.
- [ ] Update schema validation in `src/pods/recipe.lua`.
- [ ] Integrate hooks into lifecycle events in `src/pods/pod.lua` and `src/pods/container.lua`.
- [ ] Add lifecycle integration tests in `tests/pods/test_pod.lua` and `tests/pods/test_container.lua`.
- [ ] Update `USAGE.md` with new CLI syntax and hook documentation.
- [ ] Add entry to `CHANGELOG.md`.

### 3.2 Work Log & Decisions
* **2026-09-26:** Initial concept created. Designed to support both Lua callbacks and shell commands for maximum flexibility without requiring external dependencies. Safe execution via `pcall` established for Lua. Refactored proposal to match the JEP-style 3-part template.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
