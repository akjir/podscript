---
id: PSP-003
title: Volume Host Directory Verification & Automatic Creation
status: concept
type: feature
created: 2026-09-25
updated: 2026-10-10
---

# PSP-003: Volume Host Directory Verification & Automatic Creation

## Part 1: Concept & Proposal

### 1.1 Summary
Recipes frequently define bind mounts (e.g., relative `./data` or absolute host paths). If a host directory does not exist prior to container launch, Podman may fail or automatically create the directory under root ownership. This proposal introduces pre-checking of volume directories to prevent runtime failures and ensure directories are initialized under the appropriate user permissions. A new configuration option `auto_create_directories` will control whether missing directories are automatically created or if an error is raised.

### 1.2 Motivation
In rootless setups, if a host path bound to a container does not exist, Podman might automatically create it, but it may end up with root ownership, leading to permission issues. Alternatively, the container launch fails entirely. Pre-checking and conditionally creating these directories beforehand with the correct (current user) permissions provides a smoother out-of-the-box experience and prevents permission-related bugs. Using a configuration option allows strict environment control by default while offering an opt-in convenience feature.

### 1.3 Goals & Non-Goals
* **Goals:**
    * Detect non-existent host volume mount paths before launching containers.
    * Introduce a new configuration option `settings.auto_create_directories` (default: `false`).
    * If `auto_create_directories` is `false`: Emit an error and abort container creation when directories are missing.
    * If `auto_create_directories` is `true`: Emit a warning and automatically create missing directories (equivalent to `mkdir -p`) with current user permissions.
    * Abort container creation if directory creation fails.
    * Apply this logic strictly to `create` (and `recreate`), but omit it for `update` (which primarily deals with images).
    * Respect `--simulate` mode by logging intended creations/errors without touching the filesystem.
* **Non-Goals:**
    * Modifying or creating named Podman volumes (named volumes are managed by Podman's volume subsystem).
    * Modifying existing directory permissions if the folder already exists.

### 1.4 Description
* **Configuration:** Add `auto_create_directories = false` to the default `config.lua` template under the `settings` block.
* Runs transparently during `pods create` and `pods recreate` (ignored during `pods update`).
* **When `auto_create_directories` is `false` (default):**
    * If a directory is missing, Logs: `ERROR: Volume host directory does not exist: '/path/to/dir'.`
    * Aborts the creation of the pod/container.
* **When `auto_create_directories` is `true`:**
    * If a directory is missing, Logs: `WARNING: Volume host directory does not exist: '/path/to/dir'. Creating directory.`
    * Creates the directory before invoking `podman run` with current user permissions.
    * If creation fails, aborts with an error.
* **When `--simulate` is active:**
    * Logs intended validations, warnings, errors, or creations without modifying the disk.

### 1.5 Alternatives
* Manual creation by the user prior to running PodScript. This is the default behavior now (when option is false), but offering an opt-in auto-creation improves developer experience.
* Allowing Podman to create it and fixing permissions after. Rejected because rootless Podman may fail outright or we might not have permissions to `chown` after the fact.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/config.lua` (or init templates)
* `src/pods/utilities_system.lua`
* `src/pods/container.lua`

### 2.2 Schema & Syntax Changes
* Introduce `settings.auto_create_directories` in the `config.lua` structure. The default value should be `false`. `pods init` templates need to be updated to include this option.

### 2.3 Implementation Details
* **Configuration:**
    * Add `auto_create_directories = false` to the configuration definition and `init` templates.
* **Directory Helpers in `utilities_system.lua`:**
    * Add `system.directory_exists(path)` using `test -d` or `io.open`.
    * Add `system.make_directory(path, simulate)` executing `mkdir -p`. Check the return code and return success/failure.
* **Volume Path Resolution in `container.lua`:**
    * In `container__create`, iterate over `container.volumes`.
    * For each entry with a host directory (ignoring empty or purely container-internal mounts), verify existence using `system.directory_exists`.
    * Based on `context.config.settings.auto_create_directories`:
        * If missing and option is false: throw error, abort.
        * If missing and option is true: log warning, call `system.make_directory`. If it fails, throw error, abort.
    * Do not execute this check during `pods update`.

### 2.4 Testing Strategy
* Update default configuration test cases.
* Mock directory existence and creation checks.
* Test with relative host paths (`./data`), absolute paths (`/tmp/pod_test`), and nonexistent paths.
* Test behavior when `auto_create_directories` is `true` vs `false`.
* Test failure paths when directory creation fails (e.g. no permissions).
* Verify behavior under `--simulate`.
* Add test cases to `tests/pods/suite_008_containers.lua` or `tests/pods/suite_009_utilities_system.lua`.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [ ] Update `config.lua` and `mode_init.lua` templates to include `auto_create_directories = false` under `settings`.
- [ ] Create test stubs for new behavior in `tests/pods/`.
- [ ] Add `system.directory_exists(path)` and `system.make_directory(path, simulate)` to `src/pods/utilities_system.lua`.
- [ ] Implement volume check logic in `src/pods/container.lua` (`container__create`).
- [ ] Maintain "Living Document": Update Part 1 & 2 to reflect actual implementation if it diverged from the original plan.
- [ ] Build release (`lua build.lua`).
- [ ] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [ ] Update `USAGE.md` to document the new `auto_create_directories` configuration option.
- [ ] Add entry to `CHANGELOG.md` for this feature.
- [ ] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [ ] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-003-volume-dir-check.md`.
* **2026-09-26:** Refactored proposal to match 3-part template.
* **2026-10-10:** Extended proposal with `auto_create_directories` configuration option and strict error handling.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
