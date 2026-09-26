---
id: PSP-003
title: Volume Host Directory Verification & Automatic Creation
status: concept
type: feature
created: 2026-09-25
updated: 2026-09-26
---

# PSP-003: Volume Host Directory Verification & Automatic Creation

## 1. Summary & Motivation
Recipes frequently define bind mounts (e.g., relative `./data` or absolute host paths). If a host directory does not exist prior to container launch, Podman may either fail or automatically create the directory under root ownership, leading to permission issues in rootless setups. Pre-checking volume directories prevents runtime failures and ensures directories are initialized under the appropriate user permissions.

## 2. Goals & Non-Goals
* **Goals:**
    * Detect non-existent host volume mount paths before launching containers.
    * Emit an informative warning via `log.warning(...)`.
    * Automatically create missing directories (equivalent to `mkdir -p`) with current user permissions.
    * Respect `--simulate` mode by logging intended creations without touching the filesystem.
* **Non-Goals:**
    * Modifying or creating named Podman volumes (named volumes are managed by Podman's volume subsystem).
    * Modifying existing directory permissions if the folder already exists.

## 3. Specification & CLI Syntax
* **Behavior:**
    * Runs transparently during `pods create`, `pods recreate`, and `pods update`.
    * If a directory is missing:
        * Logs: `WARNING: Volume host directory does not exist: '/path/to/dir'. Creating directory.`
        * Creates the directory before invoking `podman run`.
    * When `--simulate` is active:
        * Logs: `Create directory '/path/to/dir'` without modifying disk.

## 4. Technical Architecture
* **Directory Helpers in `system.lua`:**
    * Add `system.directory_exists(path)` using `test -d` or `io.open`.
    * Add `system.make_directory(path, simulate)` executing `mkdir -p`.
* **Volume Path Resolution in `container.lua`:**
    * In `container__create`, iterate over `container.volumes`.
    * For each entry with a host directory (ignoring empty or purely container-internal mounts), verify existence and trigger creation if missing.
* **Affected Files:**
    * `src/pods/system.lua`
    * `src/pods/container.lua`

## 5. Test Strategy (TDD)
* Mock directory existence and creation checks.
* Test with relative host paths (`./data`), absolute paths (`/tmp/pod_test`), and nonexistent paths.
* Verify behavior under `--simulate`.
* Add test cases to `tests/pods/suite_008_containers.lua` or `tests/pods/suite_009_system.lua`.

## 6. Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-003-volume-dir-check.md`.
