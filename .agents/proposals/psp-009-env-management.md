---
id: PSP-009
title: Environment Variable Management (.env Integration)
status: concept
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-009: Environment Variable Management (.env Integration)

## 1. Summary & Motivation
Users currently hardcode environment variables and sensitive configuration values directly inside `recipe.lua`. This introduces security risks when recipes are committed to version control and makes it difficult to reuse recipes across different environments (e.g., development, staging, production). This feature introduces native support for loading variables from `.env` files and injecting them into Podman containers, separating configuration from the declarative recipes.

## 2. Goals & Non-Goals
* **Goals:**
  * Parse standard `.env` files (KEY=VALUE).
  * Automatically resolve a local `.env` file if it exists, or load one explicitly via a CLI flag.
  * Inject the parsed environment variables into containers at runtime via Podman's `--env-file` or `--env` arguments.
* **Non-Goals:**
  * Variable interpolation *within* the `.env` file itself (e.g., `A=$B`).
  * Full bash-like environment variable expansion.

## 3. Specification & CLI Syntax
* **CLI Syntax Addition:**
  * Add a global `--env-file=<path>` option to all modes.
  * Example: `pods --env-file=.env.production create web-stack`
* **Recipe Schema Addition:**
  * Support an `env_file = ".env"` field at the root `pod` level or within individual `containers` tables.
* **Resolution Order:**
  1. CLI Flag (`--env-file`)
  2. Recipe definition (`env_file`)
  3. Default fallback to `.env` in the current working directory (if it exists).
* **Execution:**
  * Pass the resolved absolute path directly to `podman run --env-file=<path>` to avoid internal Lua parsing overhead where possible, relying on Podman's native `.env` parser.

## 4. Technical Architecture
* **Affected Files:**
  * `src/pods/config.lua`: Add `env_file` default configuration.
  * `src/pods-converter/container.lua`: Append `--env-file=<path>` to the generated Podman commands.
  * `src/pods/main.lua`: Parse the new `--env-file` global CLI flag.
* **Function Signatures:**
  * Add a `utilities.file_exists(path)` check in `utilities.lua` to safely verify `.env` fallback presence.
* **Strict Lua 5.5:** Ensure no globals are used. `global<const>` directives must be maintained.

## 5. Test Strategy (TDD)
* **Tests:** Create a new test suite in `tests/pods/009_env_management.lua`.
* **Edge Cases:**
  * File does not exist (should gracefully ignore default `.env`, but error on explicit `--env-file` flag).
  * Relative vs. absolute paths for the `--env-file` option.
  * Validating `podman run` string generation in `simulate` mode.

## 6. Work Log & Decisions
* **2026-09-26:** Initial concept created.
