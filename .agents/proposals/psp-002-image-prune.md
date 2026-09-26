---
id: PSP-002
title: Orphaned & Dangling Image Cleanup
status: concept
type: feature
created: 2026-09-25
updated: 2026-09-26
---

# PSP-002: Orphaned & Dangling Image Cleanup

## Part 1: Concept & Proposal (JEP-Style)

### 1.1 Summary
A built-in mechanism for PodScript to safely purge orphaned and dangling container images to reclaim disk space.

### 1.2 Motivation
Continuous recipe updates, rebuilds, and test cycles accumulate untagged dangling layers (`<none>:<none>`) and stale container images on the host. PodScript needs a native capability to purge these orphaned images safely without requiring the user to drop out of the PodScript interface and rely on manual Podman commands.

### 1.3 Goals & Non-Goals
* **Goals:**
    * Automatically identify and prune dangling container images.
    * Provide dry-run (`--dry-run` / `--simulate`) to preview reclaimable disk space before deletion.
    * Provide explicit flags for pruning all unused images vs. only dangling images.
* **Non-Goals:**
    * Pruning active images used by running or configured stopped containers.
    * Managing system-wide storage volumes or Podman cache unrelated to images.

### 1.4 Description
The proposed feature introduces a new `prune` (or `image prune`) command to the PodScript CLI.
* **CLI Command:**
    * `pods prune [OPTIONS]` or `pods image prune [OPTIONS]`
* **Options:**
    * `--all`: Prune all unused images, not just dangling ones.
    * `--simulate` / `--dry-run`: Preview images and space that would be deleted without executing deletion.
    * `--force` / `-f`: Skip interactive confirmation prompt.

### 1.5 Alternatives
* Utilizing direct `podman image prune` commands outside of PodScript. Rejected because PodScript aims to be a unified interface for managing pods and containers, and switching contexts disrupts the user workflow and tool consistency.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/main.lua` (subcommand dispatch for `prune`)
* `src/pods/mode_prune.lua` (new mode handler)
* `src/pods/system.lua` (system command executions)

### 2.2 Schema & Syntax Changes
No changes to `config.lua` or recipe schemas are anticipated, as this is purely a CLI operational command.

### 2.3 Implementation Details
* **Command Execution:**
    * Wrap `podman image prune` with default dangling filter: `podman image prune -f`.
    * For `--all`: execute `podman image prune -a -f`.
    * For simulation (`--simulate`): run `podman images --filter dangling=true` and format the output to show what would be deleted without actually executing the prune operation.

### 2.4 Testing Strategy
* Test prune mode dispatch in dry-run/simulate mode.
* Verify flag combinations (`--all`, `--force`, `--simulate`).
* Require new test suite in `tests/pods/suite_018_mode_prune.lua`.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Create test stubs in `tests/pods/suite_018_mode_prune.lua`.
- [ ] Implement core logic in `src/pods/mode_prune.lua`.
- [ ] Update `src/pods/main.lua` to route the `prune` command.
- [ ] Update `USAGE.md` with new CLI syntax.
- [ ] Add entry to `CHANGELOG.md`.

### 3.2 Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-002-image-prune.md` and refactored to the new 3-part template.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
