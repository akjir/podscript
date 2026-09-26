---
id: PSP-014
title: Command Mode Syntax Alignment
status: concept
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-014: Command Mode Syntax Alignment

## Part 1: Concept & Proposal (JEP-Style)

### 1.1 Summary
PodScript CLI syntax currently follows the pattern `pods [mode] <action> <target(s)>` in almost all modes. We propose restructuring the `command` mode to strictly align with this standard pattern by introducing explicit actions and updating target definitions.

### 1.2 Motivation
The `command` mode currently uses `pods command <recipe> <command>`, violating the established convention by reversing target and action, and treating the recipe-specific maintenance command as the action. This inconsistency creates friction for users. Restructuring it ensures total CLI predictability and consistency.

### 1.3 Goals & Non-Goals
* **Goals:** 
  * Align the `command` mode strictly with the standard CLI syntax pattern `mode action target`.
  * Introduce explicit, static actions (`list`, `run`/`exec`).
  * Group the recipe and its command logically into a single target parameter (`<recipe>:<command>`).
* **Non-Goals:**
  * Do not change how commands are structurally defined in the `recipe.lua` schemas.
  * No support for executing commands across multiple recipes concurrently in this iteration.

### 1.4 Description
The new syntax will shift from `pods command [OPTIONS] <recipe> [command|index]` to `pods command [OPTIONS] <action> <target>`.
Available actions will be `list` (default if omitted), `run` (or `exec`), and `help`.
For `list`, the target is the `<recipe>` name.
For `run`, the target will combine the recipe and the command using a colon separator: `<recipe>:<command_name_or_index>`.
Examples:
* `pods command list web-stack` (Lists all valid commands for the recipe)
* `pods command run web-stack:migrate` (Executes the migrate command)
* `pods command run web-stack:1` (Executes the 1st command)
* `pods command help`

### 1.5 Alternatives
* Keeping the existing syntax: Rejected due to CLI inconsistency.
* Using separate flags like `--recipe web-stack --command migrate`: Rejected as it breaks the positional argument flow used by other modes.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* **Affected files:** 
  * `src/pods/mode_command.lua` (core logic update).
  * `src/pods/mode_simulate.lua` (parameter parsing updates for simulation).

### 2.2 Schema & Syntax Changes
No changes to `config.lua` or recipe schemas. The changes only affect CLI syntax parsing inside the command mode handler.

### 2.3 Implementation Details
* Parse `action` from `registry.parameters[1]`.
* If `action` is `help`, call `mode_command__help()`.
* If `action` is `list`, the `target` is `registry.parameters[2]`.
* If `action` is `run` or `exec`, the `target` is `registry.parameters[2]`. The `target` string must be split at the first `:` to extract the `recipe_name` and the `command_name`.
* **Error Handling:** Log a clear error if the `:` is missing for `run` actions, or if no target is provided.

### 2.4 Testing Strategy
* **Test Suites:** Update tests in `tests/pods/test_mode_command.lua`.
* **Test Cases:**
  * Verify `list` action displays commands for a given recipe.
  * Verify `run` action correctly splits `<recipe>:<command>` and executes the Podman command.
  * Verify error handling when `target` is missing for `run`.
  * Verify error handling when the `:` separator is missing in `run`.
  * Verify simulation mode works seamlessly with the new syntax.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Update tests in `tests/pods/test_mode_command.lua` for the new syntax.
- [ ] Implement parameter parsing and logic changes in `src/pods/mode_command.lua`.
- [ ] Update `src/pods/mode_simulate.lua` to support the new command mode syntax.
- [ ] Update `USAGE.md` with new `command` mode CLI syntax.
- [ ] Add entry to `CHANGELOG.md`.

### 3.2 Work Log & Decisions
* **2026-09-26:** Initial concept created based on CLI structural consistency review. Refactored proposal to new template format.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
