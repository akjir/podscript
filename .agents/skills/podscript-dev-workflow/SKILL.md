---
name: podscript-dev-workflow
description: >-
  Build, test, and develop PodScript. Covers build.lua annotations, test.lua suites, and CHANGELOG.md conventions.
---

# PodScript Development Workflow

## 1. Edit-Build-Test Cycle
1. **Verify Baseline:** Run `./task verify` before you edit files.
2. **Edit:** Modify source files in `src/pods/` or `src/pods-converter/`.
3. **Test & Build:** Run `./task verify [testID]` (or `./task [testID]`) to run dev tests, build `pods.lua`, and run release tests.
   * Run `./task test dev [testID]` to run dev tests only.
   * Run `./task test build` to test the build system.
   * Run `./task build --release` to build a release without the `.dev` suffix.
4. **Sync Docs & Templates:** Read and follow **`update-documentation`** to update `USAGE.md`, `README.md`, CLI help, and `.pods-completion.bash` when CLI syntax, schemas, or requirements change. Update `config.lua`, `recipe.lua`, `AGENTS.md`, and `CHANGELOG.md`.

## 2. Build Annotations (`build.lua`)
* `---@build block:`: Start included code block (ignores preceding `require` calls).
* `---@build global:`: Keep `global function` in release builds (default converts to `local function`).
* `---@build const:`: Convert `[global] VAR[<const>] = ...` to `local VAR <const> = ...`.
* `---@build insert:{"PLACEHOLDER", "PATH"}`: Replace `{"PLACEHOLDER"}` with the escaped string content of `PATH`.
* **New Files:** Add `---@build block:` to the file, `require` it for dev mode, and append its path to `files` in `build.lua`.

## 3. Testing (`test.lua`)
* **Paths:** `tests/pods/suite_*.lua` and `tests/pods-converter/suite_*.lua`.
* **IDs:** Use 5-digit IDs: 3-digit suite + 2-digit test (e.g., `[s .. "01"] = { -- 00401`).
* **Types:** Mode tests compare CLI output against `expectations`. Unit tests compare `run` return values against `expected`.
* **Expectations:** Match log output (including `[file:line]` prefixes) with `contains`, `sequence`, `not_contains`, `matches` (Lua patterns), and `count`.
* **Flags:** `--dev` (source files), `--fail-fast` (stop on first error), `--json` (JSON output).
* **Dev-Only:** Set `dev_only = true` to skip tests for localized functions in release mode.
* **Failures:** Re-run failed tests by ID (`lua test.lua 00101 --dev`) to view the full stack trace.

## 4. Changelog Rules (`CHANGELOG.md`)
* **Sections:** Use `Added`, `Changed`, `Fixed`, `Removed`.
* **Format:** Write one sentence of 6–15 words (50–85 chars, max 90) ending with a period: `[Past Verb] [Subject] [context (to/for/in)].`
* **Verbs:** Start with `Added`, `Updated`, `Renamed`, `Optimized`, `Improved`, `Fixed`, or `Removed` (never use `Added` under `### Changed`).
* **Scope:** Document user-facing changes only. Omit refactorings and test changes. Wrap code symbols, flags, modes, and keys in backticks.

## 5. Coding Guidelines
* **Documentation:** Document every function in English above its definition with LuaCATS (`---`, `@param`, `@return`).
* **Validation:** Validate arguments at the start of each function (e.g., `if type(context) ~= "table" then error("...", 2) end`).
* **Nil-Safety:** Provide fallback tables before iteration (e.g., `local groups = context.config.recipes.groups or {}`).
