---
name: podscript-dev-workflow
description: >-
  Build, test, and develop PodScript. Covers build.lua annotations, test.lua suites, and CHANGELOG.md conventions.
---

# PodScript Development Workflow

## 1. Edit-Build-Test Cycle
1. **Edit:** `src/pods/` modular files.
2. **Test Dev:** `lua test.lua --dev [testID]` (always first).
3. **Build:** `lua build.lua` (concatenates `src/pods/` into `pods.lua`; use `--release` to omit `.dev` suffix).
4. **Test Release:** `lua test.lua [testID]` (final verification).
5. **Docs:** Update `CHANGELOG.md`, `AGENTS.md`, and `USAGE.md` as needed.

## 2. Build System Annotations (`build.lua`)
* `---@build block:`: Starts included code block (ignores preceding dev `require`s).
* `---@build global:`: Preserves `global function` in release (otherwise localized to `local function`).
* `---@build const:`: Transforms `[global] VAR[<const>] = ...` to `local VAR <const> = ...`.
* **New files:** Add to `src/pods/` with `---@build block:`, require for dev, append to `files` table in `build.lua`.

## 3. Testing (`test.lua`)
* **Locations:** `tests/pods/suite_*.lua` and `tests/pods-converter/suite_*.lua`.
* **IDs:** Explicit 5-digit literal IDs: 3-digit suite + 2-digit test (e.g. `00401`).
* **Types:** Mode tests (CLI output capture vs `expectations`), Code tests (`run` function vs `expected`).
* **Dev-Only:** `dev_only = true` skips test in release mode (for internal functions localized during build).

## 4. Changelog Rules (`CHANGELOG.md`)
* **Format:** [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) sections (`Added`, `Changed`, `Fixed`, `Removed`).
* **Structure:** Single sentence of 6–15 words (~50–85 chars, max 90) ending with a period: `[Past Verb] [Subject/Feature] [context clause (to/for/in)].`
* **Verbs:** Lead with capitalized past-tense verb (`Added`, `Updated`, `Renamed`, `Refactored`, `Optimized`, `Improved`, `Fixed`, `Removed`; never "Added" under `### Changed`).
* **Scope:** Focus on feature/user impact. Avoid sprawling explanations or internal function lists.
* **Exclusions:** Do not document test additions, changes, or updates.
* **Formatting:** Wrap code symbols, CLI flags, modes, keys, and function names in backticks (`--debug`, `table.create`).
