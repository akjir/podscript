---
id: PSP-004
title: Recipe List Cross-Check (Config vs. Filesystem)
status: concept
type: feature
created: 2026-09-25
updated: 2026-09-26
---

# PSP-004: Recipe List Cross-Check (Config vs. Filesystem)

## 1. Summary & Motivation
Currently, `pods recipe list` only enumerates recipes declared in `registry.recipes.groups` in `config.lua`. Unconfigured recipe files sitting on disk are invisible, while configured recipes whose `.lua` files are missing on disk are printed without warning or description. Providing a bidirectional cross-check gives users complete visibility over recipes and configuration drift.

## 2. Goals & Non-Goals
* **Goals:**
    * Compare configured recipe names (`registry.recipes.groups`) with physical files on disk (`registry.recipes.path`).
    * Flag missing recipe files in the output (e.g., `[file missing]`).
    * Expose unlinked/orphaned recipe files that exist on disk but are not referenced in the active configuration (e.g., `[unconfigured]`).
* **Non-Goals:**
    * Automatically deleting orphaned recipe files.
    * Automatically editing `config.lua` to register newly discovered files.

## 3. Specification & CLI Syntax
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

## 4. Technical Architecture
* **Directory Scanning in `system.lua`:**
    * Helper `system.list_files(directory, extension)` to scan files without external dependencies.
* **Comparison in `mode_recipe.lua`:**
    * `mode_recipe__list` builds two sets: configured targets from groups and file targets from filesystem.
    * Sort and format output based on status.
* **Affected Files:**
    * `src/pods/system.lua`
    * `src/pods/mode_recipe.lua`

## 5. Test Strategy (TDD)
* Test with:
    * Fully synced configuration (all files present).
    * Missing recipe file referenced in config.
    * Unconfigured recipe file present on disk.
* Add test cases to `tests/pods/suite_012_mode_recipe.lua`.

## 6. Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-004-recipe-list-crosscheck.md`.
