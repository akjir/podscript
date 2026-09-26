---
id: PSP-014
title: Command Mode Syntax Alignment
status: concept
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-014: Command Mode Syntax Alignment

## 1. Summary & Motivation
PodScript CLI syntax follows the strict pattern `pods [mode] <action> <target(s)>` in almost all modes.
However, the `command` mode currently uses `pods command <recipe> <command>` which violates this convention by reversing target and action, and treating the recipe-specific maintenance command as the action.
To ensure total CLI consistency, we will restructure the `command` mode. We will introduce explicit actions (`list`, `run`) and bind the recipe-specific command directly to the recipe target using a colon separator (e.g., `web-stack:migrate`).

## 2. Goals & Non-Goals
* **Goals:** 
  * Align the `command` mode strictly with the standard CLI syntax pattern `mode action target`.
  * Introduce explicit, static actions (`list`, `run`/`exec`).
  * Group the recipe and its command logically into a single target parameter (`<recipe>:<command>`).
* **Non-Goals:**
  * Do not change how commands are structurally defined in the `recipe.lua` schemas.
  * No support for executing commands across multiple recipes concurrently in this iteration.

## 3. Specification & CLI Syntax
* **Old Syntax:** `pods command [OPTIONS] <recipe> [command|index]`
* **New Syntax:** `pods command [OPTIONS] <action> <target>`
  * **Actions:** 
    * `list` (default if omitted)
    * `run` (or `exec`)
    * `help`
  * **Target format for `list`:** `<recipe>` (e.g., `web-stack`)
  * **Target format for `run`:** `<recipe>:<command_name_or_index>` (e.g., `web-stack:migrate` or `web-stack:1`)
* **Examples:**
  * `pods command list web-stack` (Lists all valid commands for the recipe)
  * `pods command run web-stack:migrate` (Executes the migrate command)
  * `pods command run web-stack:1` (Executes the 1st command)
  * `pods command help`

## 4. Technical Architecture
* **Affected files:** `src/pods/mode_command.lua` (and possibly `src/pods/mode_simulate.lua` parameter parsing).
* **Implementation Details:**
  * Parse `action` from `registry.parameters[1]`.
  * If `action` is `help`, call `mode_command__help()`.
  * If `action` is `list`, the `target` is `registry.parameters[2]`.
  * If `action` is `run` or `exec`, the `target` is `registry.parameters[2]`. The `target` string must be split at the first `:` to extract the `recipe_name` and the `command_name`.
* **Error Handling:** Log a clear error if the `:` is missing for `run` actions, or if no target is provided.

## 5. Test Strategy (TDD)
* **Test Suites:** Update tests in `tests/pods/test_mode_command.lua`.
* **Test Cases:**
  * Verify `list` action displays commands for a given recipe.
  * Verify `run` action correctly splits `<recipe>:<command>` and executes the Podman command.
  * Verify error handling when `target` is missing for `run`.
  * Verify error handling when the `:` separator is missing in `run`.
  * Verify simulation mode works seamlessly with the new syntax.

## 6. Work Log & Decisions
* **2026-09-26:** Initial concept created based on CLI structural consistency review.
