---
id: PSP-011
title: Pre/Post Execution Hooks
status: concept
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-011: Pre/Post Execution Hooks

## 1. Summary & Motivation
Users frequently need to perform setup and teardown tasks before or after pod/container lifecycles. Examples include database migrations, directory creation, network configuration, or notifying external systems. This feature introduces a hook system allowing PodScript recipes to define shell commands or Lua callbacks tied to lifecycle events like `pre_create`, `post_create`, `pre_remove`, etc.

## 2. Goals & Non-Goals
* **Goals:**
  * Support Lua callbacks and shell commands (strings or arrays).
  * Provide hooks for major lifecycle events: `pre_create`, `post_create`, `pre_start`, `post_start`, `pre_stop`, `post_stop`, `pre_remove`, `post_remove`.
  * Ensure safe execution using `pcall` for Lua callbacks and robust execution for shell commands.
  * Stop/abort the lifecycle operation if a `pre_` hook fails (non-zero exit or Lua error).
* **Non-Goals:**
  * Interactive prompts during hooks.
  * Long-running daemon hooks (all hooks must be synchronous and terminate).

## 3. Specification & CLI Syntax
### Recipe Schema Additions
Recipes and individual container definitions can include a `hooks` table:

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

### Execution Rules
1. **Lua Callbacks:** Invoked via `pcall(callback, context)`. Must return `true` or `nil` on success. Returning `false` or throwing an error via `error()` fails the hook.
2. **Shell Commands (String):** Executed via standard system shell (e.g. `system.execute` mapping to `os.execute`). Standard shell semantics apply.
3. **Command Arrays:** Elements are automatically shell-escaped to prevent injection, then executed.
4. **Failure Behavior:** If a hook fails, execution halts. For a `pre_` hook, the associated action (e.g. creation, start) is skipped. The CLI will abort with a non-zero exit code.

## 4. Technical Architecture
* **`src/pods/recipe.lua`**: Update schema validation to allow `hooks` tables at both the recipe (pod) and container levels.
* **`src/pods/hook.lua` (New Module):** 
  * Expose `hook__run(hook_definition, context)`.
  * Internal dispatch logic to distinguish between `type(hook) == "function"`, `"string"`, and `"table"`.
  * Use `pcall` to safely invoke Lua functions.
  * Delegate to `system.*` for shell command execution, incorporating robust escaping for table inputs.
* **Lifecycle Integration (`src/pods/pod.lua` & `src/pods/container.lua`):**
  * Insert `hook__run` calls around existing podman execution blocks (e.g., before and after `podman pod create`, `podman run`, etc.).
  * Handle hook failures cleanly by bubbling up errors via `log.error` and aborting the sequence.
* **Strict Globals & Lua 5.5:** Ensure the new hook system complies with `global<const> *` restrictions.

## 5. Test Strategy (TDD)
* **Hook Execution Logic (`tests/pods/test_hook.lua`):**
  * Test Lua callbacks (success, explicit failure via `error()`, return false).
  * Test shell command execution (string format and array formats with escaping).
* **Lifecycle Integration (`tests/pods/test_pod.lua` / `test_container.lua`):**
  * Verify `pre_create` failure prevents pod/container creation.
  * Verify `post_create` executes only if the creation command succeeds.
* **Failure Modes:**
  * Ensure environment remains clean, errors are cleanly bubbled up to the CLI, and exit codes accurately reflect hook failures.

## 6. Work Log & Decisions
* **2026-09-26:** Initial concept created. Designed to support both Lua callbacks and shell commands for maximum flexibility without requiring external dependencies. Safe execution via `pcall` established for Lua.
