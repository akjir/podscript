---
id: PSP-019
title: Interactive Container Shell Access (`connect` mode)
status: planned
type: feature
created: 2026-10-04
updated: 2026-10-04
---

# PSP-019: Interactive Container Shell Access (`connect` mode)

## Part 1: Concept & Proposal

### 1.1 Summary
Introduce a new CLI mode, `pods connect`, providing interactive shell access (specifically `bash` falling back to `sh`) to a running container.

### 1.2 Motivation
Developers frequently need to enter a running container for debugging, manual inspection, or executing ad-hoc commands not predefined in the recipe. Currently, this requires manually looking up the container name and executing verbose `podman exec -it <container> bash` commands. A native `pods connect` mode streamlines this workflow.

### 1.3 Goals & Non-Goals
* **Goals:**
    * Add `pods connect [ACTION] <target>` as a top-level mode (analogous to `logs`). The default action is `shell`.
    * Target an individual container using the same string parsing mechanism utilized by `mode_logs.lua` (`<recipe>[/<container>]`).
    * Allow omitting the container name if the recipe contains only a single container.
    * Alternatively, allow connecting directly to a container using its full, absolute name.
    * Execute `podman exec -it <generated_container_name> sh -c "bash || sh"` safely using `system.exec` with the `interactive` option (introduced in PSP-020) to preserve standard terminal I/O.
* **Non-Goals:**
    * Executing predefined recipe commands (already implemented via `pods command exec`).
    * Executing detached/background commands.

### 1.4 Description
Users will use `pods connect shell <target>` (or just `pods connect <target>`, defaulting to `shell`) to open an interactive shell session inside a container. The system attempts to launch `bash` by default, falling back to `/bin/sh` if `bash` is unavailable (e.g., in Alpine Linux).

**Syntax rules:**
* `pods connect shell <recipe>`: If the recipe has exactly 1 container, it connects to it. If it has multiple, it aborts with an error prompting the user to specify the container.
* `pods connect shell <recipe>/<container>`: Connects directly to the specified container defined in the recipe.
* `pods connect shell <absolute_container_name>`: Connects directly to the container matching the exact absolute name provided, bypassing recipe parsing if no matching recipe exists.
* Supports standard parameters like `--config=NAME` and `--debug`. `--simulate` will print the target command instead of executing.

**Execution:**
Under the hood, it constructs and runs `podman exec -it <absolute_container_name> sh -c "bash || sh"`. Since it's interactive, it must allocate a TTY. It will use the refactored `system.exec` utility (from PSP-020) with the `interactive` option, ensuring standard input/output/error streams are fully attached to the user's terminal without any redirection or capture.

### 1.5 Alternatives
* `pods interact`: Considered, but `connect` is shorter and clearly implies establishing a session.
* `pods exec`: Recently implemented in `mode_command` (`pods command exec`) for executing explicitly predefined script commands in the container. `connect` serves a different use-case, targeting arbitrary interactive bash shell sessions.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/mode_connect.lua` (New mode to handle target parsing, validation, and execution. Keeps logic strictly separated from `mode_default.lua` which is built for bulk multi-target/group operations).
* `src/pods/main.lua` (Register `connect = mode_connect__handle` in the global `modes` dictionary).
* `src/pods/mode_simulate.lua` (Add `connect` logic or simply rely on standard simulation flags as done in other modes).
* `src/pods/mode_help.lua` (Add `connect` to the main help menu).
* `.pods-completion.bash` (Add `connect` to autocompletion).

### 2.2 Schema & Syntax Changes
* No config schema changes.
* CLI syntax addition: `pods connect [OPTIONS] [ACTION] <target>`. `ACTION` defaults to `shell`. `target` can be `<recipe>[/<container>]` or `<absolute_container_name>`.

### 2.3 Implementation Details
1. **Target Parsing (`mode_connect.lua`)**:
   * Extract the target argument `context.parameters[1]`.
   * Check for `help` and redirect to `mode_connect__help(context)`.
   * Split the target by `/` into `recipe_name` and `container_spec`. (Similar logic to `mode_logs__execute`). If no `/` is found, `recipe_name` is the full target and `container_spec` is nil.
2. **Validation & Resolution**:
   * Try to load the recipe using `recipe__load(context.config.recipes.path, recipe_name)`.
   * **If the recipe exists and is valid:**
       * If `container_spec` is omitted, check `#loaded_recipe.containers`. If `== 1`, assign `container_spec = "1"`. If `> 1`, throw a fatal error.
       * Resolve the absolute container name using: `recipe__resolve_container_name(loaded_recipe, container_spec)`.
   * **If the recipe does not exist:**
       * If `container_spec` is omitted (i.e., no `/` was provided), treat `recipe_name` as an `<absolute_container_name>`.
       * Validate it directly by proceeding to the Early Validation step. If it fails, report that neither a valid recipe nor a running container by that name could be found.
3. **Early Validation (Status Check)**:
   * Before executing the command, use `system.container_exists(abs_container_name)` to ensure the container is currently running. If not, cleanly abort with `log.error(...)` to prevent messy raw Podman errors.
4. **Command Construction & Security**:
   * Escape the absolute container name using `string.escape_shell(abs_container_name)`.
   * Construct the command: `podman exec -it " .. escaped_name .. " sh -c 'bash || sh'`.
5. **Execution & Process Handling**:
   * Execute the constructed command using `system.exec(command_str, { interactive = true, simulate = context.flags.simulate, silent = true })`.

### 2.4 Testing Strategy
* Create `tests/pods/suite_015_mode_connect.lua`.
* Use `--simulate` (dry-run mode) to verify command construction for single-container fallback, explicit `/container` targets, and fallback to absolute container names.
* Test error paths: missing target, invalid recipe, missing container, missing specification for multi-container recipes, and non-existent absolute container names.
* Fully automated tests for the interactive TTY are generally impractical, so string construction and simulation verification is the critical focus.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [ ] Implement `src/pods/mode_connect.lua` with help menu and execution logic.
- [ ] Register `connect` mode in `src/pods/main.lua` and `src/pods/mode_simulate.lua`.
- [ ] Update `src/pods/mode_help.lua` to document the new `connect` mode.
- [ ] Update `.pods-completion.bash` to support the new `connect` mode.
- [ ] Add tests in `tests/pods/suite_015_mode_connect.lua` to verify target resolution and command construction.
- [ ] Build release (`lua build.lua`).
- [ ] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [ ] Update `USAGE.md` to detail the new `connect` syntax and behavior.
- [ ] Add entry to `CHANGELOG.md` under "Added".
- [ ] Set status to `review`, update `README.md` board, request manual user approval.
- [ ] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-10-04:** Initial concept drafted. `connect` chosen over `interact` for brevity. Designed as a dedicated mode (analogous to `logs`) rather than a default bulk action to properly handle interactive 1-to-1 container targeting, leveraging `recipe__resolve_container_name`.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
