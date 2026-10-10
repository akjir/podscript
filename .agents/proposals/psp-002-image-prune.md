---
id: PSP-002
title: Orphaned & Dangling Image Cleanup
status: planned
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
    * `--force` / `-f`: Skip the interactive confirmation prompt.

### 1.5 Alternatives
* Utilizing direct `podman image prune` commands outside of PodScript. Rejected because PodScript aims to be a unified interface for managing pods and containers, and switching contexts disrupts the user workflow and tool consistency.
* Using the global `--simulate` mode. Rejected because `--simulate` is globally designed to just echo the command that *would* be run without querying the system state, whereas we want `--preview` to actively query Podman for actual image data to provide an accurate preview of what will be deleted and the space reclaimed.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/main.lua`: Update the main command router (`main__execute`) to dispatch the new `image` mode.
* `src/pods/mode_image.lua`: A newly created mode handler module. This file will strictly enforce Lua 5.5 type checking and use `global<const> *` to maintain strict variable scope.
* `src/pods/mode_help.lua`: Add the `image` mode and its usage instructions to the general help output.
* `tests/pods/suite_018_mode_image.lua`: A new test suite dedicated to the image mode implementation.

### 2.2 Schema & Syntax Changes
No changes to `config.lua` or recipe schemas are anticipated, as this is purely a CLI operational mode. The CLI syntax will be extended to accept `image` as a valid top-level mode argument.

### 2.3 Implementation Details
* **New File `src/pods/mode_image.lua`:**
    * **Module Setup:** Must begin with `global<const> *` to enforce strict globals.
    * **Dispatch Function:**
      ```lua
      global function mode_image__execute(context)
      ```
      Must strictly begin with early type validation (`if type(context) ~= "table" then error("...", 2) end`) to prevent silent failures. Validate `context.action` against an allowed list (`["prune"] = true`, `["help"] = true`) and dispatch to local action handlers.
    * **Action `prune`:**
      ```lua
      local function mode_image__prune(context)
      ```
      Checks `context.flags.all`, `context.flags.preview`, and `context.flags.force`.
    * **Action `help`:**
      ```lua
      local function mode_image__help(context)
      ```
      Outputs usage specific to `pods image`.

* **Preview Query Execution & Parsing:**
    * If `--preview` is passed, do NOT run `podman image prune`.
    * Use the `system.exec_capture(command)` function (from `src/pods/utilities_system.lua`) which securely returns standard output as a Lua table without JSON dependencies.
    * **Command:** `podman images --filter dangling=true --format "{{.ID}};;;{{.Repository}};;;{{.Tag}};;;{{.Size}}"`
      (If `--all` is passed, omit the dangling filter).
    * Split the returned lines natively using `string.split(line, ";;;")`.
    * Track and sum the sizes, which typically come as `MB`, `GB` strings. A helper function must safely convert these to bytes for accurate summation, then format them back to a human-readable string.
    * Display the matched images using `util.format_line(line, size_str, target_column)` to maintain visual parity with existing CLI tables.

* **Actual Prune Command Execution:**
    * If `--preview` is NOT passed, execute actual pruning.
    * Construct the base command: `podman image prune -f` (always force since PodScript handles confirmation if needed, or bypasses it if `-f` is passed via CLI).
    * Append `-a` if `--all` is provided.
    * Use `system.exec` (from `src/pods/utilities_system.lua`) to run the command interactively or capture its output for the user, handling potential errors.

### 2.4 Testing Strategy
* Create `tests/pods/suite_018_mode_image.lua` to enforce TDD.
* **Test cases:**
    * Invalid action dispatching falls back to an error or help menu.
    * `mode_image__action_help` produces expected output lines.
    * Mock Podman outputs (mocking `system.exec_capture`) to strictly test size conversions and `util.format_line` formatting.
    * Verify flag variations (`--all`, `--force`, `--preview`).

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
- [ ] Update CLI help menu (`src/pods/mode_help.lua`, action-specific help) if applicable.
- [ ] Update `.pods-completion.bash` if CLI syntax or modes changed.
- [ ] Update relevant `.agents/skills/*.md` if agent workflows or capabilities changed.
- [ ] Add entry to `CHANGELOG.md` (skip for internal test/dev/refactoring changes).
- [ ] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [ ] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-002-image-prune.md` and refactored to the new 3-part template.
* **2026-10-05:** Refined proposal to introduce `mode image` with `prune` and `help` actions, explicitly separating `--preview` from the global `--simulate` flag.
* **2026-10-10:** Expanded technical design details (Code paths, `system.exec_capture`, `global<const>`), reset status back to `concept` based on review.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
