---
id: PSP-004
title: Recipe List Cross-Check (Config vs. Filesystem)
status: planned
type: feature
created: 2026-09-25
updated: 2026-10-04
---

# PSP-004: Recipe List Cross-Check (Config vs. Filesystem)

## Part 1: Concept & Proposal

### 1.1 Summary
This proposal introduces a bidirectional cross-check mechanism for `pods recipe list`, designed to compare recipes declared in the configuration with actual recipe files on disk, ensuring total visibility. It will heavily leverage the validation tags, alignment logic, and directory scanning utilities introduced in [PSP-017](psp-017-human-config-output.md) and [PSP-018](psp-018-human-recipe-output.md).

### 1.2 Motivation
Currently, `pods recipe list` only enumerates recipes declared in `config.lua`. Unconfigured recipe files sitting on disk are invisible, while configured recipes whose `.lua` files are missing on disk are printed without warning or description. Providing a bidirectional cross-check gives users complete visibility over recipes and helps prevent configuration drift.

### 1.3 Goals & Non-Goals
* **Goals:**
    * Compare configured recipe names with physical files on disk.
    * Flag missing recipe files in the CLI output (e.g., `[NOT FOUND]`) to align with PSP-017 and PSP-018.
    * Expose unlinked/orphaned recipe files that exist on disk but are not referenced in the active configuration (e.g., `[UNREFERENCED]`).
    * Consistently align the validation tags for readability, reusing formatting logic from PSP-017.
    * Print summary sentences for missing or unreferenced files at the end of the output, matching the style in PSP-017 and PSP-018.
* **Non-Goals:**
    * Automatically deleting orphaned recipe files.
    * Automatically editing `config.lua` to register newly discovered files.

### 1.4 Description
* **CLI Command:**
    * `pods recipe list [OPTIONS]`
* **Options:**
    * Default: Shows configured recipes, annotating valid files with `[OK]` and missing files with `[NOT FOUND]`.
    * `--all` / `--orphans`: Appends unconfigured recipes found on disk under an "Unlinked Recipes" subsection, marked as `[UNREFERENCED]`.
* **Output Format:**
    ```text
    Recipes:
      1) web: Web application server            [OK]
      2) db (database): PostgreSQL database     [OK]
      3) cache                                  [NOT FOUND]

    Unlinked Recipe Files:
      4) legacy_service.lua                     [UNREFERENCED]

    Validation Summary:
    - Recipe file for 'cache' not found!
    - Potentially unreferenced recipe file 'legacy_service.lua' found!
    ```

### 1.5 Alternatives
* Do nothing and rely on OS tools (`ls`). Rejected because it breaks the tool's goal of being a centralized management interface.
* Break on missing files instead of warning. Rejected because it prevents the user from viewing their other valid configurations or using commands for valid recipes.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* **Affected Files:**
    * `src/pods/mode_recipe.lua`
    * (Utilizes `src/pods/utilities_system.lua` functions already introduced in PSP-017)

### 2.2 Schema & Syntax Changes
* No changes required for `config.lua` schemas.
* Addition of `--all` and `--orphans` flag arguments to the `pods recipe list` command line.

### 2.3 Implementation Details
* **Directory Scanning & Validation:**
    * Reuse the `system.list_directory(path, pattern)` and `system.file_exists(path)` functions introduced in PSP-017. There is no need to implement new low-level directory scanning functions.
* **Comparison in `mode_recipe.lua`:**
    * `mode_recipe__list` will build two tables (sets): configured targets retrieved from the context configuration, and file targets obtained from the filesystem via `system.list_directory`.
    * It will compute the intersection and differences to categorize recipes as 'configured', 'missing', or 'unconfigured'.
    * Sort and format output based on status.
    * Reuse padding/alignment logic developed for PSP-017 and PSP-018 to strictly align the status tags.

### 2.4 Testing Strategy
* Test scenarios to add to `tests/pods/test_mode_recipe.lua`:
    * A fully synced configuration where all configured files are physically present on disk.
    * A missing recipe file that is still referenced in the config.
    * An unconfigured recipe file present on disk but absent in the config.
    * Assert the presence of the validation summary strings.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [ ] Implement the cross-check logic in `src/pods/mode_recipe.lua` using `system.list_directory` from PSP-017.
- [ ] Apply consistent tag alignment (`[OK]`, `[NOT FOUND]`, `[UNREFERENCED]`) and print summary warnings.
- [ ] Add list cross-check edge cases and validation formatting assertions to `tests/pods/test_mode_recipe.lua`.
- [ ] Maintain "Living Document": Update Part 1 & 2 to reflect actual implementation if it diverged from the original plan.
- [ ] Build release (`lua build.lua`).
- [ ] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [ ] Update `USAGE.md` with the new CLI syntax for `pods recipe list`.
- [ ] Update CLI help menu (`mode_help.lua` or action-specific help) for the new `--all` / `--orphans` flags.
- [ ] Update `.pods-completion.bash` for the new `--all` and `--orphans` flags.
- [ ] Add entry to `CHANGELOG.md`.
- [ ] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [ ] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-004-recipe-list-crosscheck.md`.
* **2026-09-26:** Refactored proposal to match the new 3-part template.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
