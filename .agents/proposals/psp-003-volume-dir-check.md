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
    * Introduce a new configuration option `auto_create_directories` at the root level of the configuration (default: `false`).
    * If `auto_create_directories` is `false`: Emit an error and abort container creation when directories are missing.
    * If `auto_create_directories` is `true`: Emit a warning and automatically create missing directories (equivalent to `mkdir -p`) with current user permissions.
    * Abort container creation if directory creation fails.
    * Apply this logic strictly to `create` (and `recreate`), but omit it for `update` (which primarily deals with images).
    * Respect `--simulate` mode by logging intended creations/errors without touching the filesystem.
* **Non-Goals:**
    * Modifying or creating named Podman volumes (named volumes are managed by Podman's volume subsystem).
    * Modifying existing directory permissions if the folder already exists.

### 1.4 Description
* **Configuration:** Add `auto_create_directories = false` to the default `config.lua` template at the root level (alongside options like `editor`).
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
* `src/pods/config.lua` (and `mode_init.lua` for default templates)
* `src/pods/utilities_system.lua`
* `src/pods/container.lua`

### 2.2 Schema & Syntax Changes
* Introduce `auto_create_directories` in the `config.lua` structure at the root level. The default value should be `false`. The repository's main `config.lua` needs to be updated to include this option.

### 2.3 Implementation Details
*   **Configuration Defaults:**
    *   Modify the repository's root `/config.lua` and any default config initialization to include `auto_create_directories = false` at the root configuration level (the `mode_init.lua` template automatically embeds the root `/config.lua` via the build system).
* **Directory Helpers in `utilities_system.lua`:**
    * **Reuse Existing Validation:** Utilize the already existing `function system.directory_exists(full_path)` to check for directory presence.
    * **Safe Creation Function:** Implement `function system.make_directory(full_path, simulate)`.
        * **Command Injection Prevention:** The path must be strictly escaped before execution (e.g., `local safe_path = "'" .. full_path:gsub("'", "'\\''") .. "'"`).
        * **No Console Spam:** Execute `mkdir -p` with `2>/dev/null` appended to suppress raw shell errors from leaking into the terminal.
        * **Execution:** If `simulate` is `true`, it only logs the intended action. Otherwise, it executes the escaped command. Check the return code and emit the failure cleanly via `log.error` if creation fails.
* **Volume Path Resolution in `container.lua`:**
    * In `global function container__create(context, container, config)`, iterate over `container.volumes` before invoking the container run command.
    * **Strict Type Checking (Early Validation):** For each entry `local host_dir = container.volumes[i][1]`, explicitly verify that it exists and `type(host_dir) == "string"` to prevent silent failures.
    * Ensure it is a host directory path (e.g., starts with `/` or `.`), skipping named volumes.
    * Use `system.directory_exists(host_dir)` to verify existence.
    * Check `context.config.auto_create_directories`:
        * If `false` and directory is missing: `log.error("Volume host directory does not exist: " .. host_dir)` and return an error or invoke `os.exit(1)`.
        * If `true` and directory is missing: `log.warning("Volume host directory does not exist: " .. host_dir .. ". Creating directory.")`, then call `system.make_directory(host_dir, context.simulate)`. If creation fails, log the error cleanly and abort.
* **Note:** Avoid singletons and global state to preserve test runner isolation; rely on explicit parameter passing via `context`. Ensure action-specific flags (if any were added) are explicitly separated from global flags (e.g., `--simulate`).

### 2.4 Testing Strategy
* Update default configuration test cases.
* Mock `system.exec` to intercept `test -d` and `mkdir -p` commands.
* Test with relative host paths (`./data`), absolute paths (`/tmp/pod_test`), and nonexistent paths.
* Test behavior when `auto_create_directories` is `true` vs `false`.
* Test failure paths when directory creation fails (e.g. no permissions).
* Verify behavior under `--simulate`.
* Add test cases to `tests/pods/suite_008_containers.lua` or `tests/pods/suite_009_utilities_system.lua`.
* **Note:** Ensure mock configurations do not trigger unwanted shell side-effects (e.g., suppress shell errors by mocking appropriately).

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [ ] Create test stubs for new behavior in `tests/pods/`.
- [ ] Implement core logic in `src/pods/` (ensure idiomatic naming conventions).
    * [ ] Update the repository's root `/config.lua` to include `auto_create_directories = false`.
    - [ ] Add `function system.make_directory` to `utilities_system.lua`.
    - [ ] Add the strict type verification and directory check loop in `container__create`.
- [ ] Maintain "Living Document": Update Part 1 & 2 to reflect actual implementation if it diverged from the original plan.
- [ ] Build release (`lua build.lua`).
- [ ] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [ ] Update `USAGE.md` with new CLI syntax/configuration options.
- [ ] Update `README.md` (check for broken markdown tables) and `AGENTS.md` (update Architecture list if files were added/removed).
- [ ] Update CLI help menu (e.g. `mode_help.lua`, action-specific help) if applicable.
- [ ] Update `.pods-completion.bash` if CLI syntax or modes changed.
- [ ] Update relevant `.agents/skills/*.md` if agent workflows or capabilities changed.
- [ ] Add entry to `CHANGELOG.md` (skip for internal test/dev/refactoring changes).
- [ ] Set status to `review`, update `BOARD.md`, and request manual user review and approval.
- [ ] Manual approval received; set status to `completed`, update `BOARD.md`, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-003-volume-dir-check.md`.
* **2026-09-26:** Refactored proposal to match 3-part template.
* **2026-10-10:** Extended proposal with `auto_create_directories` configuration option and strict error handling. Aligned the structure with latest `TEMPLATE.md` changes.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
