---
name: update-documentation
description: >-
  Update USAGE.md and README.md when CLI syntax, features, or core capabilities change.
---

# Updating Documentation

## 1. Triggers
Update documentation when you change:
* **CLI Syntax:** Modes, actions, flags, or target patterns (also update `.pods-completion.bash` and CLI help).
* **Features & Schemas:** Lifecycle steps, configuration keys, or recipe formats (also update root `config.lua` and `recipe.lua`).
* **Requirements:** Podman, Lua, or OS versions.

## 2. `README.md` Rules
* Describe high-level features and system requirements.
* Keep examples brief and defer full CLI details to `USAGE.md`.

## 3. `USAGE.md` Rules
* Keep the section hierarchy: `## Mode Name`, `### Actions`, `### Options`, `### Usage`.
* Use aligned markdown tables for Modes, Actions, and Options.
* Write a one-sentence description and provide at least one example for every action or option.
* Wrap all CLI commands, modes, actions, and flags in backticks (e.g., `--debug`).

## 4. General Rules
* Document only implemented, verified features.
* Use generic placeholders (`example-app`, `db-server`, `app-cli`) in examples; never use real application names (`nextcloud`, `postgres`, `php`).
* Update all affected sections when a flag or feature applies to multiple modes.
