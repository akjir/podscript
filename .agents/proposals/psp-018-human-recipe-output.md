---
id: PSP-018
title: Human-Readable Recipe Output
status: concept
type: feature
created: 2026-10-04
updated: 2026-10-04
---

# PSP-018: Human-Readable Recipe Output

## Part 1: Concept & Proposal

### 1.1 Summary
Analogous to [PSP-017](psp-017-human-config-output.md), this proposal aims to replace the raw JSON/Lua dump currently output by the `pods recipe show <recipe>` command with a structured, human-readable, and diagnostic view of the recipe's configuration. The new output will provide a clear overview of containers, ports, volumes, and other properties, validate local host paths for volumes, and reuse formatting functions developed in PSP-017 where applicable.

### 1.2 Motivation
Currently, `pods recipe show` reads the recipe file and prints it to the terminal as a raw data dump. A raw dump provides no additional insight compared to simply looking at the file (e.g. `pods recipe edit`). By transforming the output into a formatted diagnostic tool, users can instantly understand the structure of the recipe and see if required local host directories for volumes exist, saving debugging time.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Provide a clean, formatted terminal output for `pods recipe show <recipe>`.
  * Display containers and their essential configurations (image, ports, volumes, environment variables) in a readable way.
  * Validate if local host paths defined in volumes exist.
  * Consistently align the validation tags (`[OK]`, `[NOT FOUND]`) for readability, sharing layout/printing code with the `config show` implementation (from PSP-017).
  * Print summary sentences for missing local volume paths.
  * Completely remove old code and tests related to the raw JSON/Lua dumping of recipes.
* **Non-Goals:**
  * Modifying how recipes are parsed or executed.
  * Changing the `pods recipe edit` behavior.

### 1.4 Description
When a user runs `pods recipe show <recipe>`, the system will load the recipe and print it in a human-readable format with runtime validation. The output will look like this:

```text
Recipe: /home/user/project/myrecipe.lua

Containers:
  • web
    Image:      nginx:latest
    Ports:      8080:80
    Volumes:    /var/www:/usr/share/nginx/html      [NOT FOUND]

  • db
    Image:      postgres:15
    Env:        POSTGRES_USER=admin
    Volumes:    ./data:/var/lib/postgresql/data     [OK]

Validation Summary:
- Local volume path '/var/www' for container 'web' not found!
```

### 1.5 Alternatives
* **Keep existing behavior:** Rejected because raw dumps offer no real value over `pods recipe edit`.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/mode_recipe.lua`: The `mode_recipe__show` function will be rewritten.
* **Shared formatting:** Code that aligns tags and handles structured output should ideally be shared with or adapted from `src/pods/mode_config.lua` (as introduced in PSP-017) to ensure a consistent CLI experience and avoid duplication.

### 2.2 Schema & Syntax Changes
No changes to the actual recipe schema. The changes are strictly confined to the standard output format of `pods recipe show`.

### 2.3 Implementation Details
1. **`src/pods/mode_recipe.lua` Changes:**
   * **Remove:** Completely remove the raw dumping logic from `mode_recipe__show`. Any internal helper functions specifically created for generating the raw dump should also be removed if not used elsewhere.
   * **Rewrite `mode_recipe__show(context, recipe_name)`:**
     * Print a formatted header.
     * Iterate over the containers defined in the recipe and print their key properties (Image, Ports, Volumes, Env, etc.) in a clear, indented list.
     * Check local host paths defined in `Volumes` using `system.directory_exists` or `system.file_exists` (reusing utilities if applicable).
     * Reuse padding/alignment logic developed for PSP-017 to strictly align `[OK]` and `[NOT FOUND]` tags for volumes.
     * Print the final summary warnings for missing local volume paths.

### 2.4 Testing Strategy
* **`tests/pods/test_mode_recipe.lua`:**
   * Remove old tests that assert the output matches the raw JSON/Lua dump format.
   * Add tests for the new structured string output, ensuring properties (ports, volumes, images) are correctly displayed.
   * Test `recipe show` with valid volumes (assert `[OK]` tags and no warnings).
   * Test `recipe show` with missing local volume paths (assert `[NOT FOUND]` and summary warning).

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [ ] Identify and remove raw dump logic from `mode_recipe.lua` and related unused code.
- [ ] Remove corresponding tests for raw output.
- [ ] Rewrite `mode_recipe__show` to output formatted, human-readable text.
- [ ] Validate local volume paths and share/reuse alignment and string formatting functions from `PSP-017`.
- [ ] Add summary warnings for missing local volume paths.
- [ ] Write new tests verifying the human-readable format and validation.
- [ ] Build release (`lua build.lua`).
- [ ] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [ ] Add entry to `CHANGELOG.md`.
- [ ] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [ ] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-10-04:** Initial concept drafted to replace raw recipe dumps with formatted, human-readable output, ensuring code reuse from PSP-017 and removal of unused dump code/tests.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
