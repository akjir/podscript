---
id: PSP-002
title: Orphaned & Dangling Image Cleanup
status: planned
type: feature
created: 2026-09-25
updated: 2026-10-05
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
    * `--force` / `-f`: Skip the interactive confirmation prompt.

### 1.5 Alternatives
* Utilizing direct `podman image prune` commands outside of PodScript. Rejected because PodScript aims to be a unified interface for managing pods and containers, and switching contexts disrupts the user workflow and tool consistency.
* Using the global `--simulate` mode. Rejected because `--simulate` is globally designed to just echo the command that *would* be run without querying the system state, whereas we want `--preview` to actively query Podman for actual image data to provide an accurate preview of what will be deleted and the space reclaimed.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/main.lua`: Update the main command router to dispatch the `image` mode.
* `src/pods/mode_image.lua`: A new mode handler module containing the logic for the `image` mode and its specific actions.

### 2.2 Schema & Syntax Changes
No changes to `config.lua` or recipe schemas are anticipated, as this is purely a CLI operational mode.

### 2.3 Implementation Details
* **New Functions to Create in `src/pods/mode_image.lua`:**
    * `global function mode_image__execute(context)`: Main dispatcher for the `image` mode. **Must strictly begin with early type validation (`if type(context) ~= "table" then error("...") end`) to prevent silent failures and cascading bugs.** Validates actions against an allowed list (`["prune"] = true`, `["help"] = true`) and calls the appropriate action function.
    * `local function mode_image__action_prune(context)`: Handles the `prune` action. **Must strictly begin with early type validation (`if type(context) ~= "table" then error("...") end`).** Checks `context.flags.all`, `context.flags.preview`, and `context.flags.force`.
    * `local function mode_image__action_help(context)`: Displays help text specific to the `image` mode and its actions.
* **Preview Query Execution & Parsing:**
    * If `--preview` is passed, do NOT run `podman image prune`.
    * Instead, execute a read-only query explicitly using `system.exec_capture` to leverage our validated, zero-dependency method for securely parsing Podman CLI outputs into Lua tables:
      `podman images --filter dangling=true --format "{{.ID}};;;{{.Repository}};;;{{.Tag}};;;{{.Size}}"`
      (If `--all` is passed, omit the dangling filter).
    * Parse the output by splitting lines with `;;;`.
    * Calculate the total reclaimed space by parsing the size strings (e.g., converting "MB", "GB" to bytes for summation, then formatting back to a human-readable string).
    * Output a structured list of images that would be deleted, followed by the total estimated reclaimable space. **Mandatory: Use the existing utility function `util.format_line` to format this list. This ensures Image IDs, Repositories, and Sizes are precisely and robustly aligned, maintaining the same visual consistency as the Config-Tree status tags.**
* **Actual Prune Command Execution:**
    * Construct the base command: `podman image prune -f` (always force since PodScript handles confirmation if needed, or bypasses it if `-f` is passed via CLI).
    * If `--all` is passed, append `-a`.
    * Use `system.exec_capture` or standard execution to run the prune command and relay the output to the user.

### 2.4 Testing Strategy
* Require a new functional test suite in `tests/pods/suite_018_mode_image.lua`.
* **Tests to Implement:**
    * Test mode dispatch for `image` and verify that invalid actions fail gracefully.
    * Test `pods image help` output.
    * Mock Podman outputs to test `pods image prune --preview` formatting and space calculation.
    * Verify proper behavior of flag combinations (`--all`, `--force`, `--preview`).

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [ ] Create test stubs in `tests/pods/suite_018_mode_image.lua`.
- [ ] Implement core logic in `src/pods/mode_image.lua` (`mode_image__execute`, `mode_image__action_prune`, `mode_image__action_help`).
- [ ] Update `src/pods/main.lua` to route the `image` mode.
- [ ] Maintain "Living Document": Update Part 1 & 2 to reflect actual implementation if it diverged from the original plan.
- [ ] Build release (`lua build.lua`).
- [ ] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [ ] Update `USAGE.md` with new CLI syntax.
- [ ] Update CLI help menu (e.g., `mode_help.lua`, action-specific help) if applicable.
- [ ] Update `.pods-completion.bash` if CLI syntax or modes changed.
- [ ] Update relevant `.agents/skills/*.md` if agent workflows or capabilities changed.
- [ ] Add entry to `CHANGELOG.md` (skip for internal test/dev/refactoring changes).
- [ ] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [ ] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-002-image-prune.md` and refactored to the new 3-part template.
* **2026-10-05:** Refined proposal to introduce `mode image` with `prune` and `help` actions, explicitly separating `--preview` from the global `--simulate` flag and enforcing strict early validation and zero-dependency parsing.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
