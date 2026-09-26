---
id: PSP-003
title: Volume Host Directory Verification & Automatic Creation
status: concept
type: feature
created: 2026-09-25
updated: 2026-09-26
---

# PSP-003: Volume Host Directory Verification & Automatic Creation

## Part 1: Concept & Proposal (JEP-Style)

### 1.1 Summary
Recipes frequently define bind mounts (e.g., relative `./data` or absolute host paths). If a host directory does not exist prior to container launch, Podman may fail or automatically create the directory under root ownership. This proposal introduces pre-checking of volume directories to prevent runtime failures and ensure directories are initialized under the appropriate user permissions.

### 1.2 Motivation
In rootless setups, if a host path bound to a container does not exist, Podman might automatically create it, but it may end up with root ownership, leading to permission issues. Alternatively, the container launch fails entirely. Pre-checking and creating these directories beforehand with the correct (current user) permissions provides a smoother out-of-the-box experience and prevents permission-related bugs.

### 1.3 Goals & Non-Goals
* **Goals:**
    * Detect non-existent host volume mount paths before launching containers.
    * Emit an informative warning via `log.warning(...)`.
    * Automatically create missing directories (equivalent to `mkdir -p`) with current user permissions.
    * Respect `--simulate` mode by logging intended creations without touching the filesystem.
* **Non-Goals:**
    * Modifying or creating named Podman volumes (named volumes are managed by Podman's volume subsystem).
    * Modifying existing directory permissions if the folder already exists.

### 1.4 Description
* Runs transparently during `pods create`, `pods recreate`, and `pods update`.
* If a directory is missing:
    * Logs: `WARNING: Volume host directory does not exist: '/path/to/dir'. Creating directory.`
    * Creates the directory before invoking `podman run`.
* When `--simulate` is active:
    * Logs: `Create directory '/path/to/dir'` without modifying disk.

### 1.5 Alternatives
* Manual creation by the user prior to running PodScript. Rejected because it reduces the "declarative recipe" value of PodScript and makes the developer experience cumbersome.
* Allowing Podman to create it and fixing permissions after. Rejected because rootless Podman may fail outright or we might not have permissions to `chown` after the fact.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/system.lua`
* `src/pods/container.lua`

### 2.2 Schema & Syntax Changes
* No recipe schema or syntax changes required.

### 2.3 Implementation Details
* **Directory Helpers in `system.lua`:**
    * Add `system.directory_exists(path)` using `test -d` or `io.open`.
    * Add `system.make_directory(path, simulate)` executing `mkdir -p`.
* **Volume Path Resolution in `container.lua`:**
    * In `container__create`, iterate over `container.volumes`.
    * For each entry with a host directory (ignoring empty or purely container-internal mounts), verify existence and trigger creation if missing.

### 2.4 Testing Strategy
* Mock directory existence and creation checks.
* Test with relative host paths (`./data`), absolute paths (`/tmp/pod_test`), and nonexistent paths.
* Verify behavior under `--simulate`.
* Add test cases to `tests/pods/suite_008_containers.lua` or `tests/pods/suite_009_system.lua`.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Add directory helpers to `src/pods/system.lua`.
- [ ] Implement volume check logic in `src/pods/container.lua`.
- [ ] Add tests for directory check and creation to system suite.
- [ ] Add tests for container creation intercept in container suite.
- [ ] Verify `--simulate` flag interaction.

### 3.2 Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-003-volume-dir-check.md`.
* **2026-09-26:** Refactored proposal to match 3-part template.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
