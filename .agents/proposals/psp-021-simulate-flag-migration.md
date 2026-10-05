---
id: PSP-021
title: Simulate Flag Migration
status: done
type: architecture
created: 2026-10-05
updated: 2026-10-05
---

# PSP-021: Simulate Flag Migration

## Part 1: Concept & Proposal

### 1.1 Summary
Remove the dedicated `simulate` mode in favor of standardizing on a global `--simulate` flag. The simulation state will be parsed early in `main.lua` and appended to the centralized context, gracefully removing the need for a separate routing layer.

### 1.2 Motivation
The current `simulate` mode acts as a complex routing wrapper (`mode_simulate.lua`), which intercepts execution, shifts the parameter array, and manually delegates to other modes. Using a positional `simulate` argument as a global modifier violates standard command-line conventions. Migrating to a `--simulate` flag aligns the CLI with GNU/POSIX standards for long options, where double-dashed flags modify the behavior of standard commands globally. By replacing the mode with a `--simulate` flag, we simplify the parser, standardize the user experience, and delete redundant routing code.

### 1.3 Goals & Non-Goals
* **Goals:**
    * Parse `--simulate` natively inside `main__parse_arguments`.
    * Ensure all modes (`command`, `connect`, `default`, etc.) rely exclusively on `context.flags.simulate`.
    * Delete `mode_simulate.lua` and remove it from `main.lua`'s router.
    * Forward `context.flags.simulate` reliably down to `system.exec` via its options table.
* **Non-Goals:**
    * Modifying how the simulation output actually behaves (it remains a dry-run echo).
    * Fixing or evaluating edge cases of syntax breaking (explicitly out of scope for this analytical PSP).

### 1.4 Description
Instead of writing `pods simulate create web-stack`, the user will write `pods create web-stack --simulate` or `pods --simulate create web-stack`. The generic argument parser will intercept this flag, set it in the context, remove it from the argument list, and execute the standard modes normally.

### 1.5 Alternatives
* Keeping `simulate` mode: Rejected because it requires parameter array shifting, maintains non-standard CLI syntax, and adds an unnecessary layer of complexity that flag-based architecture avoids.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
*   **`src/pods/main.lua`:**
    *   Update `main__parse_arguments`: Explicitly handle `--simulate` or rely on the generic `util.split_argument` to populate `context.flags.simulate`. Ensure configuration defaults (`config.simulate = true`) are respected and correctly overridden by the flag.
    *   Remove `require "src.pods.mode_simulate"` and its routing logic from the mode selection block.
*   **`src/pods/mode_simulate.lua`:**
    *   Delete the file completely.
*   **`src/pods/mode_*.lua` (All Modes):**
    *   Ensure help screens refer to `--simulate` instead of the `simulate` mode prefix.
    *   Verify they pass `context.flags.simulate` into `pod_actions` or `system.exec`.

### 2.2 Schema & Syntax Changes
*   CLI syntax transitions from `<mode> simulate [<action>]` to `[<mode>] [<action>] [--simulate]`.

### 2.3 Implementation Details
1.  **Argument Parsing (`main.lua`):** Update `main__parse_arguments` to iterate through the CLI arguments and specifically look for `--simulate`. When found, set `context.flags.simulate = true` and explicitly remove the flag from the arguments array so it doesn't get passed as a positional argument to the underlying modes.
2.  **Context & Config Integration:** Ensure `main__config_load_and_set`'s default `config.simulate` is synchronized with `context.flags.simulate`. If the config file defines `simulate = true` or the flag `--simulate` is passed, the final context should resolve to `true`.
3.  **Routing Cleanup (`main.lua`):** Delete the conditional branching that routes the positional `simulate` string to `mode_simulate`. Fallback logic for unhandled modes will naturally flow to `modes.default`.
4.  **Execution Forwarding:** Ensure that anywhere `system.exec` or other system operations are called, they receive `{ simulate = context.flags.simulate }` in their options table.

### 2.4 Testing Strategy (TDD)
Before changing the implementation, write rigorous test cases in `tests/pods/` to assert that:
*   **Flag Parsing:** `pods --simulate create stack` and `pods create stack --simulate` both result in `context.flags.simulate = true`.
*   **Argument Stripping:** The `--simulate` flag is successfully stripped from `context.args` and does not bleed into action arguments (e.g., `context.args[1]` is `create`, not `--simulate`).
*   **Config Precedence:** `--simulate` correctly forces dry-runs even if `config.simulate = false`.
*   **Global Enforcement:** `config.simulate = true` forces dry-runs even without the CLI flag.
*   **Mode Compatibility:** All core modes (e.g., `command`, `connect`, `default`, `recipe`) respect the `--simulate` flag seamlessly without attempting to execute actual system commands.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [x] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [x] Add failing test cases in `tests/pods/suite_021_main.lua` for `--simulate` flag parsing, argument stripping, and config precedence.
- [x] Add failing test cases in mode-specific test files ensuring `--simulate` works as a generic flag for standard modes.
- [x] Refactor `src/pods/main.lua`: Update `main__parse_arguments` to parse and strip the `--simulate` flag.
- [x] Refactor `src/pods/main.lua`: Sync `context.flags.simulate` with loaded configuration.
- [x] Refactor `src/pods/main.lua`: Remove `simulate` mode routing.
- [x] Delete `src/pods/mode_simulate.lua` and its corresponding tests.
- [x] Update help strings in `mode_help.lua` and mode-specific help functions to reflect the flag usage.
- [x] Build release (`lua build.lua`).
- [x] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [x] Update `USAGE.md` with new CLI syntax.
- [x] Update `.pods-completion.bash` to complete `--simulate`.
- [x] Add entry to `CHANGELOG.md`.
- [x] Set status to `review`, update `README.md` board, and request manual user review.

### 3.2 Work Log & Decisions
* **2026-10-05:** Concept drafted based on analysis of the current CLI architecture and insights from PSP-005 (central context) and PSP-020 (system.exec options table).
* **2026-10-05:** User requested a post-review sync. The proposal was retroactively synchronized with documentation fixes across `USAGE.md` (fixing missing `--simulate` in examples and Modes Overview), `README.md` (fixing a broken markdown table left after removing the `simulate` mode), and `AGENTS.md` (removing `mode_simulate.lua`).

### 3.3 Delivered Artifacts
* **Feature:** `--simulate` is now a global flag parsed in `main.lua` and appended to the context. `simulate` mode is completely removed.
* **Code:** `src/pods/main.lua` updated. `src/pods/mode_simulate.lua` deleted.
* **Documentation:** `USAGE.md`, `README.md`, `AGENTS.md`, and `.pods-completion.bash` fully updated. All examples refactored to use the flag.
* **Tests:** `tests/pods/suite_021_main.lua` and mode-specific tests updated and passing.
