---
id: PSP-019
title: Interactive Container Shell Access (`connect` action)
status: concept
type: feature
created: 2026-10-04
updated: 2026-10-04
---

# PSP-019: Interactive Container Shell Access (`connect` action)

## Part 1: Concept & Proposal

### 1.1 Summary
Introduce a new default CLI action, `pods connect`, providing interactive shell access (specifically `bash`) to a running container.

### 1.2 Motivation
Developers frequently need to enter a running container for debugging, manual inspection, or executing ad-hoc commands not predefined in the recipe. Currently, this requires manually looking up the container name and executing verbose `podman exec -it <container> bash` commands. A native `pods connect` action streamlines this workflow.

### 1.3 Goals & Non-Goals
* **Goals:**
    * Add `pods connect <target>` as a top-level default action.
    * Target an individual container using the `recipe/container` syntax (from `PSP-006`) or just `recipe` if the recipe contains only a single container.
    * Execute `podman exec -it <generated_container_name> sh -c "bash || sh"` safely using raw `os.execute`.
* **Non-Goals:**
    * Executing detached/background commands (that is the domain of `pods command` or regular `podman exec`).

### 1.4 Description
Users will use `pods connect <target>` to open an interactive shell session inside a container. The system attempts to launch `bash` by default, falling back to `/bin/sh` if `bash` is unavailable (e.g., in Alpine Linux).

**Syntax rules:**
* `pods connect <recipe>`: If the recipe has exactly 1 container, it connects to it. If it has multiple, it aborts with an error prompting the user to specify the container.
* `pods connect <recipe>/<container>`: Connects directly to the specified container.

**Execution:**
Under the hood, it constructs and runs `podman exec -it <absolute_container_name> sh -c "bash || sh"`. Since it's interactive, it must allocate a TTY. It will use raw `os.execute` directly, completely bypassing the internal `system.exec` utility to ensure standard input/output/error streams are fully attached to the user's terminal without any redirection or capture.

### 1.5 Alternatives
* `pods interact`: Considered, but `connect` is shorter and standard in many CLI tools (like `kubectl port-forward` vs `exec`, although `exec` is also common). `connect` clearly implies establishing an interactive session.
* `pods exec`: Conflicts conceptually with `pods command` which is meant for predefined commands, or suggests it takes arbitrary commands like `docker exec`. `connect` specifically targets an interactive bash shell.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/mode_default.lua` (to register the `connect` action)
* `src/pods/pod.lua` (to implement `pod__connect(recipe_name, container_name)`)
* `src/pods/utilities.lua` (potentially leverage `parse_recipe_and_container` if implemented, or implement it here if PSP-019 lands first).

### 2.2 Schema & Syntax Changes
* No config schema changes.
* CLI syntax addition: `pods connect <recipe>[/<container>]`.

### 2.3 Implementation Details
1. **Target Parsing**: In `mode_default.lua` handling `connect`, parse the target argument. If it contains a `/`, split it into `recipe_name` and `container_name`.
2. **Validation**: 
   * Load the recipe.
   * If `container_name` is provided, ensure it exists in the recipe.
   * If not provided, check `#recipe.containers`. If `== 1`, auto-select it. If `> 1`, throw a fatal error.
3. **Early Validation (Status Check)**: Before executing the command, use `system.container_exists(abs_container_name)` (or similar status check) to ensure the container is running. If not, cleanly abort with `log.error("Container is not running.")` to prevent raw Podman error output.
4. **Security (Safe Execution)**: Escape the absolute container name to prevent command injection using `local safe_name = "'" .. abs_container_name:gsub("'", "'\\''") .. "'"`.
5. **Execution & Process Handling**: Construct the command using the fallback shell: `podman exec -it " .. safe_name .. " sh -c 'bash || sh'`. Execute this command using raw `os.execute(cmd)`. This explicitly bypasses `system.exec` (which intercepts and mutes stderr) to guarantee the interactive TTY functions properly and all standard streams (stdin, stdout, stderr) remain fully attached to the terminal.

### 2.4 Testing Strategy
* Create tests for target resolution (recipe with 1 container vs multiple containers).
* Use `--simulate` (dry-run mode) to verify the correct `podman exec` string is built.
* Note: Fully testing interactive TTY in automated Lua tests may be limited, so verifying the string output in simulation mode is critical.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [ ] Implement `pod__connect` logic in `src/pods/pod.lua`.
- [ ] Register `connect` action in `src/pods/mode_default.lua`.
- [ ] Add tests in `tests/pods/` to verify command construction and container selection logic.
- [ ] Build release (`lua build.lua`).
- [ ] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [ ] Update `USAGE.md` with new CLI syntax.
- [ ] Add entry to `CHANGELOG.md`.
- [ ] Update CLI help menu (`mode_help.lua`).
- [ ] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [ ] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-10-04:** Initial concept drafted. `connect` chosen over `interact` for brevity. Hardcoded to `bash` as per requirements.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
