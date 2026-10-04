---
id: PSP-020
title: Refactor system.exec
status: completed
type: refactor
created: 2026-10-04
updated: 2026-10-04
---

# PSP-020: Refactor system.exec

## Part 1: Concept & Proposal

### 1.1 Summary
Refactor the `system.exec` function to use a flexible options table instead of positional arguments, allowing it to fully absorb the requirements currently fulfilled by direct `os.execute` calls throughout the codebase.

### 1.2 Motivation
Currently, `os.execute` is used directly in places like `mode_logs.lua` (to retain TTY for `podman logs`) and `system.dir_exists` (to silently check exit codes). `system.exec`'s fixed positional signature (`command, prefix, simulate, direct`) and its hardcoded behavior (redirecting STDERR to `/dev/null` when `direct=true` and automatically logging errors) make it inflexible for these use cases. Consolidating all command executions under `system.exec` ensures unified handling, logging, and simulation logic.

### 1.3 Goals & Non-Goals
* **Goals:** 
  * Replace the `system.exec(command, prefix, simulate, direct)` signature with `system.exec(command, options)`.
  * Expose an `interactive` option to replace `direct`, ensuring it does not wrap commands in `( ... ) 2>/dev/null`.
  * Expose a `silent` option to suppress automatic `log.error` calls on failure.
  * Return `success, exit_reason, exit_code` from `system.exec`.
  * Replace all direct `os.execute` calls with `system.exec`.
* **Non-Goals:** 
  * Modify `system.exec_capture` (it remains as is or internally unchanged).

### 1.4 Description
`system.exec` will accept an `options` table:
* `prefix`: string (default: "")
* `simulate`: boolean (default: false)
* `interactive`: boolean (default: false)
* `silent`: boolean (default: false)

This will streamline internal code without affecting the CLI interface or user workflows.

### 1.5 Alternatives
Keeping `os.execute` scattered in the codebase leads to inconsistent simulation logging (e.g., `mode_logs.lua` manually logs its simulation). A refactored `system.exec` provides a single choke point for command execution debugging and simulation.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/utilities_system.lua` (`system.exec`, `system.dir_exists`)
* `src/pods/mode_logs.lua`
* `src/pods/pod.lua`
* `src/pods/container.lua`
* `src/pods/mode_config.lua`
* `src/pods/mode_recipe.lua`
* `src/pods/mode_command.lua`

### 2.2 Schema & Syntax Changes
No changes to external config schemas. Internal signature change for `system.exec(command, options)`.

### 2.3 Implementation Details
* Modify `system.exec` to check `options` table. Default positional mapping might be dropped to enforce the options table, requiring a refactoring of all existing call sites.
* Update `system.dir_exists` to use `system.exec(..., { interactive = true, silent = true })`.
* Update `mode_logs.lua` to use `system.exec(..., { interactive = true, simulate = context.flags.simulate, silent = true })` instead of manually printing simulation logs and calling `os.execute`.
* Remove the `( ... ) 2>/dev/null` wrapper for interactive commands.
* Ensure `system.exec` returns the results from `os.execute` or `handle:close()`.

### 2.4 Testing Strategy
* Update tests in `tests/pods/utilities_system_test.lua` to verify the new signature and options (`interactive`, `silent`).
* Verify that all pods tests still pass since `system.exec` is used extensively during pod creation/removal.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [x] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [x] Refactor `system.exec` in `src/pods/utilities_system.lua`.
- [x] Refactor all 8 existing calls to `system.exec` across the project.
- [x] Replace `os.execute` in `src/pods/mode_logs.lua`.
- [x] Replace `os.execute` in `src/pods/utilities_system.lua` (`system.dir_exists`).
- [x] Update tests in `tests/pods/utilities_system_test.lua`.
- [x] Build release (`lua build.lua`).
- [x] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [x] Add entry to `CHANGELOG.md`.
- [x] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [x] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-10-04:** Initial planned proposal.
* **2026-10-04:** Replaced `os.execute` and refactored `system.exec` to use a flexible options table. Mock configs updated to use `false` instead of `editor` to suppress shell errors. User approved.

### 3.3 Delivered Artifacts
* Refactored `system.exec` signature in `src/pods/utilities_system.lua`.
* Replaced `os.execute` with `system.exec` in `src/pods/utilities_system.lua` and `src/pods/mode_logs.lua`.
* Updated all callers of `system.exec` across all modes.
* Fixed test mock configurations (`config_012_invalid_editor.lua`, `config_013_recipe_edit.lua`) to prevent console spam.
