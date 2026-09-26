---
id: PSP-002
title: Orphaned & Dangling Image Cleanup
status: concept
type: feature
created: 2026-09-25
updated: 2026-09-26
---

# PSP-002: Orphaned & Dangling Image Cleanup

## 1. Summary & Motivation
Continuous recipe updates, rebuilds, and test cycles accumulate untagged dangling layers (`<none>:<none>`) and stale container images on the host. PodScript needs a built-in mechanism to purge orphaned images safely and reclaim disk space.

## 2. Goals & Non-Goals
* **Goals:**
    * Automatically identify and prune dangling container images.
    * Provide dry-run (`--dry-run` / `--simulate`) to preview reclaimable disk space before deletion.
    * Provide explicit flags for pruning all unused images vs. only dangling images.
* **Non-Goals:**
    * Pruning active images used by running or configured stopped containers.
    * Managing system-wide storage volumes or Podman cache unrelated to images.

## 3. Specification & CLI Syntax
* **CLI Command:**
    * `pods prune [OPTIONS]` or `pods image prune [OPTIONS]`
* **Options:**
    * `--all`: Prune all unused images, not just dangling ones.
    * `--simulate` / `--dry-run`: Preview images and space that would be deleted without executing deletion.
    * `--force` / `-f`: Skip interactive confirmation prompt.

## 4. Technical Architecture
* **Command Execution:**
    * Wrap `podman image prune` with default dangling filter: `podman image prune -f`.
    * For `--all`: `podman image prune -a -f`.
    * For simulation: run `podman images --filter dangling=true` and format output without executing prune.
* **Affected Files:**
    * `src/pods/main.lua` (subcommand dispatch)
    * `src/pods/mode_prune.lua` (new mode handler)
    * `src/pods/system.lua`

## 5. Test Strategy (TDD)
* Test prune mode dispatch in dry-run/simulate mode.
* Verify flag combinations (`--all`, `--force`, `--simulate`).
* Test suite in `tests/pods/suite_018_mode_prune.lua`.

## 6. Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-002-image-prune.md`.
