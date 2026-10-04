---
id: PSP-017
title: Human-Readable Configuration Output & Validation
status: review
type: feature
created: 2026-10-04
updated: 2026-10-04
---

# PSP-017: Human-Readable Configuration Output & Validation

## Part 1: Concept & Proposal

### 1.1 Summary
This proposal aims to replace the raw JSON/Lua dump currently output by the `pods config` (and `pods config show`) command with a structured, human-readable, and diagnostic tree view. The new output will not only display the active configuration and resolved default values but also proactively validate paths and recipe files.

### 1.2 Motivation
Currently, `pods config show` simply reads the `config.lua` file line by line and prints it to the terminal. This is redundant because users can see the exact same content by using `pods config edit`. A pure file dump provides no additional insight. By transforming the output into a diagnostic tool, users can instantly see how groups resolve, whether required directories exist, and if targeted recipes are missing or misspelled, saving significant debugging time.

### 1.3 Goals & Non-Goals
* **Goals:** 
  * Provide a clean, formatted terminal output for `pods config show`.
  * Validate if the configured `pods.path` and `recipes.path` directories exist.
  * Hierarchically expand recipe groups and validate if the corresponding `.lua` recipe files exist.
  * Identify and list any unreferenced/unused `.lua` files in the recipes directory.
  * Consistently align the validation tags (`[OK]`, `[NOT FOUND]`) for readability.
  * Print summary sentences for missing files or unreferenced files.
* **Non-Goals:** 
  * Modifying how the configuration is actually parsed or executed.
  * Changing the `pods config edit` behavior.

### 1.4 Description
When a user runs `pods config` or `pods config show`, the system will load the active configuration (with defaults applied) and perform runtime validation. The output will look like this:

```text
Configuration: /home/user/project/config.lua
============================================================

Settings:
  Editor:       vim
  Simulate:     false

Directories:
  Pods:         /pods                       [OK]
  Recipes:      .                           [OK, 4 recipes found]

Groups:
  • all
    └── recipe                              [OK]
    
  • database
    ├── postgres                            [OK]
    └── redis                               [OK]
    
  • stack
    ├── @database
    │   ├── postgres                        [OK]
    │   └── redis                           [OK]
    └── @web
        ├── api-server                      [OK]
        └── frontend                        [NOT FOUND]

Validation Summary:
- Recipe file for 'frontend' not found!
- Potentially unreferenced recipe files found: test.lua, old_stack.lua
```

### 1.5 Alternatives
* **Keep existing behavior:** Rejected because it offers no value over `pods config edit`.
* **Add a new `pods config doctor` command:** Rejected to keep the CLI surface small. `pods config show` should just be smart by default.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/utilities_system.lua`: Needs new utilities to check for directories and list files.
* `src/pods/mode_config.lua`: The entire `mode_config__show` function will be rewritten. Unused functions related to raw text printing will be removed.

### 2.2 Schema & Syntax Changes
No changes to the actual `config.lua` schema. The changes are strictly confined to the standard output format of `pods config show`.

### 2.3 Implementation Details
1. **`src/pods/utilities_system.lua` Additions:**
   * Add `system.directory_exists(path)`: Uses `io.popen("test -d ...")` or similar to check if a directory exists.
   * Add `system.list_directory(path, pattern)`: Uses `io.popen("ls -1 ...")` to retrieve a list of files in a directory to check for unreferenced `.lua` recipes.

2. **`src/pods/mode_config.lua` Changes:**
   * **Remove:** Remove the `system.read_file_content_by_line` logic from `mode_config__show`.
   * **Rewrite `mode_config__show(context)`:**
     * Print the header, active `context.config.editor`, and `context.config.simulate`.
     * Check `context.config.pods.path` and `context.config.recipes.path` using `system.directory_exists`.
     * Iterate over `context.config.recipes.groups` to print the hierarchical tree.
     * Keep track of which recipes are referenced.
     * **Validation Caching (Efficiency):** Recipes may appear multiple times across different groups. To ensure the code remains fast and efficient, cache the `system.file_exists` result for each unique recipe name in a local table (e.g., `local validation_cache = {}`). Do not perform redundant disk I/O for the same recipe.
     * Use string padding (e.g., `string.format("%-40s [%s]", line, status)`) to ensure `[OK]` and `[NOT FOUND]` tags are strictly vertically aligned.
     * Use the cached `system.file_exists` result to verify if `<recipe>.lua` exists in `context.config.recipes.path`.
     * Compare referenced recipes against the output of `system.list_directory` to find `.lua` files that exist but are never used in any group.
     * Print the final summary warnings for missing and unreferenced files.

### 2.4 Testing Strategy
* **`tests/pods/test_mode_config.lua`:**
  * Test `config show` with a fully valid configuration (assert `[OK]` tags and no warnings).
  * Test `config show` with missing directories (assert `[NOT FOUND]` on directories).
  * Test `config show` with a missing recipe in a nested group (assert `[NOT FOUND]` and summary warning).
  * Test `config show` with unreferenced files in the mock recipe directory (assert unreferenced file warning).
* **`tests/pods/suite_009_utilities_system.lua`:**
  * Add unit tests for `directory_exists` and `list_directory`.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [x] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [x] Add `directory_exists` and `list_directory` to `src/pods/utilities_system.lua` with tests.
- [x] Rewrite `mode_config__show` in `src/pods/mode_config.lua`.
- [x] Align tags using fixed-width string formatting.
- [x] Add summary warnings for missing recipes and unreferenced `.lua` files.
- [x] Build release (`lua build.lua`).
- [x] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [x] Add entry to `CHANGELOG.md`.
- [x] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [ ] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-10-04:** Initial concept drafted combining Doctor and Tree View functionality with strict alignment and summary warnings.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
