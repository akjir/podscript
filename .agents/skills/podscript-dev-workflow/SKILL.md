---
name: podscript-dev-workflow
description: >-
  Build, test, and develop PodScript. Covers build.lua annotations, test.lua suites, and CHANGELOG.md conventions.
---

# PodScript Development Workflow

## 1. Edit-Build-Test Cycle
1. **Baseline Test:** Run `./task verify` to verify a clean initial state before editing.
2. **Edit:** Modify `src/pods/` modular files.
3. **Test & Build:** Run `./task verify [testID]` (or simply `./task [testID]`) to automatically run dev tests, build `pods.lua`, and run release tests.
   * *Alternative:* Use `./task test dev [testID]` to only run dev tests without building.
   * *Alternative:* Use `./task build --release` for a clean release build without the `.dev` suffix.
4. **Docs:** Update `CHANGELOG.md`, `AGENTS.md`, and `USAGE.md` as needed.

## 2. Build System Annotations (`build.lua`)
* `---@build block:`: Starts included code block (ignores preceding dev `require`s).
* `---@build global:`: Preserves `global function` in release (otherwise localized to `local function`).
* `---@build const:`: Transforms `[global] VAR[<const>] = ...` to `local VAR <const> = ...`.
* **New files:** Add to `src/pods/` with `---@build block:`, require for dev, append to `files` table in `build.lua`.

## 3. Testing (`test.lua`)
* **Locations:** `tests/pods/suite_*.lua` and `tests/pods-converter/suite_*.lua`.
* **IDs:** Explicit 5-digit literal IDs: 3-digit suite + 2-digit test (e.g. `00401`). Found in comments next to test definition (e.g. `[s .. "01"] = { -- 00401`).
* **Types:** Mode tests (CLI output capture vs `expectations`), Unit tests (`run` function vs `expected`).
* **Expectations:** Assert log output via `contains`, `sequence` (ordered substring matching), `not_contains`, `matches` (Lua patterns), and `count`. Exact line indices are not supported. Output captures include log provenance prefixes (e.g., `[main.lua:162]`).
* **Flags:** `--dev` (use sources), `--fail-fast` (abort on first error), `--json` (machine-readable report).
* **Dev-Only:** `dev_only = true` skips test in release mode (for internal functions localized during build).
* **Failures:** When a test fails, ALWAYS re-run it directly with its ID (e.g., `lua test.lua 00101 --dev`) to get the extended stack trace.

## 4. Changelog Rules (`CHANGELOG.md`)
* **Format:** [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) sections (`Added`, `Changed`, `Fixed`, `Removed`).
* **Structure:** Single sentence of 6–15 words (~50–85 chars, max 90) ending with a period: `[Past Verb] [Subject/Feature] [context clause (to/for/in)].`
* **Verbs:** Lead with capitalized past-tense verb (`Added`, `Updated`, `Renamed`, `Optimized`, `Improved`, `Fixed`, `Removed`; never "Added" under `### Changed`).
* **Scope:** Focus on feature/user impact. Avoid sprawling explanations or internal function lists.
* **Exclusions:** Do not document pure code refactorings, test additions, test changes, or test updates.
* **Formatting:** Wrap code symbols, CLI flags, modes, keys, and function names in backticks (`--debug`, `table.create`).

## 5. Coding Guidelines
* **Early Validation**: Always validate function arguments upfront. For example, handlers receiving a `context` object should immediately verify it (e.g., `if type(context) ~= "table" or type(context.config) ~= "table" then error("...", 2) end`) to prevent cascading nil errors.
* **Nil-Safety**: Always provide defaults for optional or deeply nested structures (e.g., `local groups = context.config.recipes.groups or {}`) before iteration.
