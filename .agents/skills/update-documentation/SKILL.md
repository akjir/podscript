---
name: update-documentation
description: >-
  Use this skill to update the USAGE.md and README.md files when there are changes to the CLI syntax, features, or core functionality in the PodScript project.
---

# Updating Documentation

When code changes introduce modifications to CLI syntax, new features, or changes to core capabilities, you MUST update `USAGE.md` and `README.md` to ensure they remain accurate, professional, and concise.

## 1. Trigger Conditions
You must review and update the documentation when:
* **Syntax Changes**: A new CLI mode, action, option/flag, or target pattern is added, modified, or removed.
* **Feature Changes**: Core functionality is altered, such as new lifecycle steps, configuration file structure changes, or recipe format modifications.
* **Requirements**: Changes to supported Podman/Lua versions or OS requirements.

## 2. README.md Guidelines
The `README.md` serves as the high-level entry point for the project.
* **Scope**: Keep it brief. Focus on "What is it?" and "What can it do?".
* **Updates**: 
  * Add new high-level capabilities to the **Features** list.
  * Update **Specifications** if version requirements change.
  * Keep any code examples minimal and illustrative.
* **Style**: Professional, objective, and compact. Do not include granular CLI usage details here (defer to `USAGE.md`).

## 3. USAGE.md Guidelines
The `USAGE.md` is the comprehensive manual for CLI operations.
* **Scope**: Detailed syntax, exhaustive option lists, and practical examples.
* **Formatting**:
  * **Tables**: Always use markdown tables for listing Modes, Actions, and Options. Keep columns aligned.
  * **Code Blocks**: Enclose all CLI commands, filenames, modes, and options in backticks (`--debug`) or bash code blocks.
  * **Hierarchy**: Maintain the existing structure (`## Mode Name`, `### Actions`, `### Options`, `### Usage`).
* **Content**:
  * Ensure every new action or option is documented with a clear, single-sentence description.
  * Provide at least one concrete example under the `### Usage` or `## Examples` sections for any new syntax.

## 4. Execution Rules
* **No Speculation**: Only document features that are fully implemented and merged.
* **Consistency**: Match the tone and style of existing entries. Ensure English terminology is precise.
* **Completeness**: If a feature spans multiple modes (e.g., a flag valid in both Default and Command modes), update all relevant sections in `USAGE.md`.
