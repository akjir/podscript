---
name: update-documentation
description: >-
  Update USAGE.md and README.md when CLI syntax, features, or core capabilities change.
---

# Updating Documentation

## 1. Trigger Conditions
Review and update documentation on:
* **Syntax Changes:** Added, modified, or removed CLI modes, actions, options/flags, or target patterns. Ensure `.pods-completion.bash` is also updated to reflect these syntax changes.
* **Feature Changes:** Lifecycle steps, configuration file structure, or recipe format changes.
* **Requirements:** Supported Podman, Lua, or OS version changes.
* **Templates:** Always ensure the `config.lua` and `recipe.lua` template files in the repository root are updated when configuration or recipe options change.

## 2. README.md Guidelines
High-level entry point focusing on "What is it?" and "What can it do?".
* **Features:** Add new high-level capabilities to the feature list.
* **Specifications:** Update version requirements when changed.
* **Style:** Professional, compact, minimal illustrative examples. Defer granular CLI options to `USAGE.md`.

## 3. USAGE.md Guidelines
Comprehensive manual for CLI operations.
* **Hierarchy:** Maintain existing structure (`## Mode Name`, `### Actions`, `### Options`, `### Usage`).
* **Tables:** Use aligned markdown tables for Modes, Actions, and Options.
* **Content:** Clear, single-sentence description for every new action/option. Include at least one example (using abstract placeholders) under `### Usage` or `## Examples`.
* **Formatting:** Backtick all CLI commands, flags, modes, and options (e.g. `--debug`).

## 4. Execution Rules
* **No Speculation:** Only document verified, implemented features.
* **Abstract Examples Only:** Never use real-world applications (like `nextcloud`, `postgres`, `php`) in examples. Always use abstract, generic placeholders (like `example-app`, `db-server`, `app-cli`) to keep the documentation universally applicable.
* **Consistency:** Match tone and terminology of existing entries.
* **Completeness:** If a feature or flag spans multiple modes, update all relevant sections.
