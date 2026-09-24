---
name: podscript-dev-workflow
description: >-
  Use this skill to build, test, and release the PodScript project. Provides the mandatory 
  development workflow, build system details (build.lua, ---@build annotations), and 
  testing framework (test.lua, test suites, dev_only) guidelines.
---

# PodScript Development Workflow

Follow these rules for testing and building the PodScript project.

## 1. Development & Release Workflow
1. **Edit** `src/` modular files.
2. **Test Dev:** `lua test.lua --dev [testID]` (always first).
3. **Build:** `lua build.lua` (Concatenates `src/` into single `pods.lua`; use `--release` to omit `.dev` suffix for official releases).
4. **Test Release:** `lua test.lua [testID]` (final verification).
5. **Update docs:** Update `CHANGELOG.md`, `AGENTS.md`, and `USAGE.md` as needed.

## 2. Build System (`build.lua`)
The script processes `src/` into `pods.lua`.
* `--release`: CLI flag to produce clean release builds without the `.dev` build metadata suffix.
* `---@build block:`: Starts included code block (ignores prior dev `require`s).
* `---@build global:`: Forces global function in release. (Functions declared `global function` without this tag are localized to `local function`).
* `---@build const:`: Transforms `[global] VAR[<const>] = "1"` to `local VAR <const> = "1"`.
* **Add new file:** Add to `src/` with `block:` tag, require it for dev, add to `files` list in `build.lua`.

## 3. Testing (`test.lua`)
* **Format:** Tests are in `tests/suite_*.lua`.
* **IDs:** Suite ID is 3-digit (e.g., `004`). Test ID is `[suiteID]..[2-digit]` (e.g., `00401`). Test IDs must be explicit in code for searchability.
* **Types:** Mode tests (CLI output capture vs `expectations`), Code tests (`run` fn vs `expected`).
* **Dev-Only:** `dev_only = true` skips test in release mode (used for internal fns localized during build).

## 4. Changelog Rules (`CHANGELOG.md`)
Follow the established conventions from historical releases:
* **Format:** [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) sections (`Added`, `Changed`, `Fixed`, `Removed`).
* **Length:** Short and concise (approx. 6–15 words, ~50–85 characters, max ~90 chars). Exactly one sentence per entry ending with a period.
* **Grammar & Voice:**
  * Lead with a capitalized past-tense verb matching the section: `Added ...`, `Updated ...`, `Renamed ...`, `Refactored ...`, `Optimized ...`, `Improved ...`, `Fixed ...`, `Removed ...`.
  * Never use "Added" under `### Changed`.
* **Sentence Structure:** `[Past Verb] [Subject/Feature] [concise purpose/context clause (to/for/in)].`
* **Content Focus:** Feature- and user-facing impact. Avoid sprawling explanations or exhaustively listing multiple internal function names.
* **Exclusions:** Do not document changes, additions, or updates to tests or test suites.
* **Code Formatting:** Wrap code symbols, CLI flags, modes, keys, and function names in backticks (e.g. `--simulate`, `table.create`).

