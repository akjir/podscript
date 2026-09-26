---
id: PSP-004
title: Recipe List Cross-Check (Config vs. Filesystem)
status: concept
type: feature
created: 2026-09-25
updated: 2026-09-26
---

# PSP-004: Recipe List Cross-Check (Config vs. Filesystem)

## Part 1: Concept & Proposal (JEP-Style)

### 1.1 Summary
This proposal introduces a bidirectional cross-check mechanism for `pods recipe list`, designed to compare recipes declared in the configuration with actual recipe files on disk, ensuring total visibility.

### 1.2 Motivation
Currently, `pods recipe list` only enumerates recipes declared in `registry.recipes.groups` in `config.lua`. Unconfigured recipe files sitting on disk are invisible, while configured recipes whose `.lua` files are missing on disk are printed without warning or description. Providing a bidirectional cross-check gives users complete visibility over recipes and helps prevent configuration drift.

### 1.3 Goals & Non-Goals
* **Goals:**
    * Compare configured recipe names (`registry.recipes.groups`) with physical files on disk (`registry.recipes.path`).
    * Flag missing recipe files in the CLI output (e.g., `[file missing]`).
    * Expose unlinked/orphaned recipe files that exist on disk but are not referenced in the active configuration (e.g., `[unconfigured]`).
* **Non-Goals:**
    * Automatically deleting orphaned recipe files.
    * Automatically editing `config.lua` to register newly discovered files.

### 1.4 Description
* **CLI Command:**
    * `pods recipe list [OPTIONS]`
* **Options:**
    * Default: Shows configured recipes, annotating missing files with `[file missing]`.
    * `--all` / `--orphans`: Appends unconfigured recipes found on disk under an "Unlinked Recipes" subsection.
* **Output Format:**
    ```text
    Recipes:
      1) web: Web application server
      2) db (database): PostgreSQL database
      3) cache [file missing]

    Unlinked Recipe Files:
      4) legacy_service.lua [unconfigured]
    ```

### 1.5 Alternatives
* Do nothing and rely on OS tools (`ls`). Rejected because it breaks the tool's goal of being a centralized management interface.
* Break on missing files instead of warning. Rejected because it prevents the user from viewing their other valid configurations or using commands for valid recipes.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* **Affected Files:**
    * `src/pods/system.lua`
    * `src/pods/mode_recipe.lua`

### 2.2 Schema & Syntax Changes
* No changes required for `config.lua` schemas.
* Addition of `--all` and `--orphans` flag arguments to the `pods recipe list` command line.

### 2.3 Implementation Details
* **Directory Scanning in `system.lua`:**
    * Create a helper function `system.list_files(directory, extension)` to scan for files within a given path. It must rely strictly on standard Lua/os facilities without external dependencies, possibly by invoking a low-level OS command (like `ls` via `io.popen`) if Lua's standard library is insufficient for directory traversal.
* **Comparison in `mode_recipe.lua`:**
    * `mode_recipe__list` will build two tables (sets): configured targets retrieved from the registry, and file targets obtained from the filesystem via `system.list_files`.
    * It will compute the intersection and differences to categorize recipes as 'configured', 'missing', or 'unconfigured'.
    * Sort and format output based on status.

### 2.4 Testing Strategy
* Test scenarios to add to `tests/pods/suite_012_mode_recipe.lua`:
    * A fully synced configuration where all configured files are physically present on disk.
    * A missing recipe file that is still referenced in the config.
    * An unconfigured recipe file present on disk but absent in the config.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Implement `system.list_files` in `src/pods/system.lua`.
- [ ] Add test cases for directory scanning in the test suite.
- [ ] Implement the cross-check logic in `src/pods/mode_recipe.lua`.
- [ ] Add list cross-check edge cases to `tests/pods/suite_012_mode_recipe.lua`.
- [ ] Update `USAGE.md` with the new CLI syntax for `pods recipe list`.
- [ ] Add an entry to `CHANGELOG.md` upon completion.

### 3.2 Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-004-recipe-list-crosscheck.md`.
* **2026-09-26:** Refactored proposal to match the new 3-part template.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
