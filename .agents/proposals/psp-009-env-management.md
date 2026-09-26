---
id: PSP-009
title: Environment Variable Management (.env Integration)
status: concept
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-009: Environment Variable Management (.env Integration)

## Part 1: Concept & Proposal (JEP-Style)

### 1.1 Summary
This proposal introduces native support for loading variables from `.env` files and injecting them into Podman containers. It separates configuration from declarative recipes, eliminating the need to hardcode sensitive values or environment-specific data.

### 1.2 Motivation
Users currently hardcode environment variables and sensitive configuration values directly inside `recipe.lua`. This introduces security risks when recipes are committed to version control and makes it difficult to reuse recipes across different environments (e.g., development, staging, production). Separating configuration ensures secure, flexible deployments.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Parse standard `.env` files (KEY=VALUE).
  * Automatically resolve a local `.env` file if it exists, or load one explicitly via a CLI flag.
  * Inject the parsed environment variables into containers at runtime via Podman's `--env-file` or `--env` arguments.
* **Non-Goals:**
  * Variable interpolation *within* the `.env` file itself (e.g., `A=$B`).
  * Full bash-like environment variable expansion.

### 1.4 Description
* **CLI Syntax Addition:** Add a global `--env-file=<path>` option to all modes. Example: `pods --env-file=.env.production create web-stack`
* **Resolution Order:** 
  1. CLI Flag (`--env-file`)
  2. Recipe definition (`env_file`)
  3. Default fallback to `.env` in the current working directory (if it exists).
* **Execution:** Pass the resolved absolute path directly to `podman run --env-file=<path>` to avoid internal Lua parsing overhead where possible, relying on Podman's native `.env` parser.

### 1.5 Alternatives
* **Wrapper scripts:** Requiring users to use wrapper scripts that source `.env` files and pass variables via system environment. Rejected as it adds external dependencies and breaks the standalone nature of the tool.
* **Manual Lua parsing:** Parsing the file manually in Lua and passing individual `--env` flags. Rejected because relying on Podman's native `--env-file` flag is faster and more robust.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/config.lua`: Add `env_file` default configuration logic.
* `src/pods-converter/container.lua`: Modify command generation to append `--env-file=<path>` to the generated Podman commands.
* `src/pods/main.lua`: Update argument parsing to handle the new `--env-file` global CLI flag.
* `src/utilities.lua`: Add a `utilities.file_exists(path)` function.

### 2.2 Schema & Syntax Changes
* Support an `env_file = ".env"` field at the root `pod` level.
* Support an `env_file = ".env"` field within individual `containers` tables.

### 2.3 Implementation Details
* Add `utilities.file_exists(path)` check in `utilities.lua` to safely verify `.env` fallback presence.
* When resolving the `.env` file, normalize the path to an absolute path before passing to Podman.
* **Strict Lua 5.5:** Ensure no globals are used. `global<const>` directives must be maintained across all modified files.

### 2.4 Testing Strategy
* **Tests:** Create a new test suite in `tests/pods/009_env_management.lua`.
* **Edge Cases:**
  * File does not exist (should gracefully ignore default `.env`, but error on explicit `--env-file` flag).
  * Relative vs. absolute paths for the `--env-file` option.
  * Validating `podman run` string generation in `simulate` mode ensuring the path is correctly appended.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Create test stubs in `tests/pods/009_env_management.lua`.
- [ ] Implement `utilities.file_exists(path)` in `utilities.lua`.
- [ ] Update `config.lua` and recipe schema parsing to support `env_file`.
- [ ] Implement `--env-file` CLI flag parsing in `main.lua`.
- [ ] Update `container.lua` in `pods-converter` to output `--env-file` flag.
- [ ] Update `USAGE.md` with new CLI syntax.
- [ ] Add entry to `CHANGELOG.md`.

### 3.2 Work Log & Decisions
* **2026-09-26:** Initial concept created and mapped to 3-part template.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
