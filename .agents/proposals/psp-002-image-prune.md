---
id: PSP-002
title: Orphaned & Dangling Image Cleanup
status: completed
type: feature
created: 2026-09-25
updated: 2026-10-10
---

# PSP-002: Orphaned & Dangling Image Cleanup

## Part 1: Concept & Proposal

### 1.1 Summary
A built-in mechanism for PodScript to safely purge orphaned and dangling container images to reclaim disk space, implemented via a new `image` mode.

### 1.2 Motivation
Continuous recipe updates, rebuilds, and test cycles accumulate untagged dangling layers (`<none>:<none>`) and stale container images on the host. PodScript needs a native capability to purge these orphaned images safely without requiring the user to drop out of the PodScript interface and rely on manual Podman commands. Implementing this via a dedicated `image` mode establishes a clean foundation for future image-related management features.

### 1.3 Goals & Non-Goals
* **Goals:**
    * Automatically identify and prune dangling container images.
    * Introduce a new `image` mode to the PodScript CLI.
    * Support `prune` and `help` actions within the `image` mode.
    * Provide a specific `--preview` flag to preview reclaimable disk space and target images without executing deletion (distinct from the global `--simulate` flag which only prints commands).
    * Provide explicit flags for pruning all unused images vs. only dangling images.
* **Non-Goals:**
    * Pruning active images used by running or configured stopped containers.
    * Managing system-wide storage volumes or Podman cache unrelated to images.
    * Overloading the global `--simulate` mode for previews, as it serves a different purpose (command echoing).

### 1.4 Description
The proposed feature introduces a new `image` mode to the PodScript CLI, with `prune` and `help` as its primary actions.
* **CLI Command:**
    * `pods image prune [OPTIONS]`
    * `pods image help`
* **Options for `prune`:**
    * `--all`: Prune all unused images, not just dangling ones.
    * `--preview`: Preview images and space that would be deleted without executing the actual prune operation. This is handled internally by the action, unlike the global `--simulate`.
    * `--force`: Skip the interactive confirmation prompt.

### 1.5 Alternatives
* Utilizing direct `podman image prune` commands outside of PodScript. Rejected because PodScript aims to be a unified interface for managing pods and containers, and switching contexts disrupts the user workflow and tool consistency.
* Using the global `--simulate` mode. Rejected because `--simulate` is globally designed to just echo the command that *would* be run without querying the system state, whereas we want `--preview` to actively query Podman for actual image data to provide an accurate preview of what will be deleted and the space reclaimed.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/main.lua`: Update the main command router (`main__execute` - actually `main__parse_arguments` and modes table) to dispatch the new `image` mode.
* `src/pods/mode_image.lua`: A newly created mode handler module. This file strictly enforces Lua 5.5 type checking and uses `global<const> *`.
* `src/pods/mode_help.lua`: Added the `image` mode to the general help output.
* `tests/pods/suite_022_mode_image.lua`: A new test suite dedicated to the image mode implementation.

### 2.2 Schema & Syntax Changes
No changes to `config.lua` or recipe schemas. The CLI syntax was extended to accept `image` as a valid top-level mode argument.

### 2.3 Implementation Details
* **New File `src/pods/mode_image.lua`:**
    * **Module Setup:** Begins with `global<const> *`.
    * **Dispatch Function:**
      ```lua
      global function mode_image__handle(context)
      ```
      Validates `context` and dispatches to local handlers.
    * **Action `prune`:** Check flags and handle appropriately.
    * **Action `help`:** Outputs usage specific to `pods image`.

* **Preview Query Execution & Parsing:** Implemented with `system.exec_capture` formatting size strings and using `util.parse_size_to_bytes` and `util.format_bytes` added to `utilities.lua`.

* **Actual Prune Command Execution:** Built and executed with `system.exec` handling simulated run and force flag correctly.

### 2.4 Testing Strategy
* Created `tests/pods/suite_022_mode_image.lua` to enforce TDD (changed ID from 018 as 018 was already used).
* Tested flag variations, output matching and parsing mock.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [x] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [x] Create test stubs in `tests/pods/suite_022_mode_image.lua`.
- [x] Implement core logic in `src/pods/mode_image.lua` (`mode_image__handle`, `mode_image__prune`, `mode_image__help`).
- [x] Update `src/pods/main.lua` to route the `image` mode, and allow short flags (`-f`).
- [x] Maintain "Living Document": Update Part 1 & 2 to reflect actual implementation (e.g. `mode_image__handle`, suite 022).
- [x] Build release (`lua build.lua`).
- [x] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [x] Update `USAGE.md` with new CLI syntax.
- [x] Update CLI help menu (`src/pods/mode_help.lua`, action-specific help).
- [x] Update `.pods-completion.bash` if CLI syntax or modes changed.
- [x] Update relevant `.agents/skills/*.md` if agent workflows or capabilities changed (No changes needed).
- [x] Add entry to `CHANGELOG.md`.
- [x] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [x] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-002-image-prune.md` and refactored to the new 3-part template.
* **2026-10-05:** Refined proposal to introduce `mode image` with `prune` and `help` actions, explicitly separating `--preview` from the global `--simulate` flag.
* **2026-10-10:** Expanded technical design details (Code paths, `system.exec_capture`, `global<const>`), reset status back to `concept` based on review.
* **2026-10-10:** Promoted to `in-progress` and executed implementation following TDD. Renamed to `mode_image__handle` for consistency and updated suite ID to 022. Added `util.parse_size_to_bytes` and `util.format_bytes` to `utilities.lua`.

### 3.3 Delivered Artifacts
* `src/pods/mode_image.lua` (Image mode implementation)
* `tests/pods/suite_022_mode_image.lua` (Tests for image mode)
* `USAGE.md` updated with `image` mode documentation
* `.pods-completion.bash` updated with autocomplete for `image` mode
* `CHANGELOG.md` entry
