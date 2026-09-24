---
name: podscript-release
description: >-
  Automates the official release workflow for PodScript. Enforces clean working tree validation, executes pre- and post-build test suites, bumps version numbers in code and documentation, finalizes CHANGELOG.md without an empty unreleased block, compiles release builds with --release, verifies clean SemVer outputs, and creates annotated Git release tags.
---

# PodScript Release Workflow

Use this skill whenever instructed to perform a release (e.g., "Release version 1.4.0" or "1.4.1").

This workflow is strictly gate-kept: each step must succeed before moving to the next. If any check or test fails, abort and restore the working tree.

---

## 1. Pre-Flight Validation Checks

Before modifying any file, perform these mandatory safety validations:

1. **Clean Working Tree**:
   * Run: `git status --porcelain`
   * Output **must be completely empty**.
   * If there are uncommitted changes, staged changes, or untracked files, **abort immediately**. Request that the user commit, stash, or clean their working tree before proceeding.

2. **Branch Check**:
   * Verify current branch: `git branch --show-current`
   * Confirm the release is being cut from `main` (or the intended release branch).

3. **Version Syntax & Monotonicity**:
   * Normalize input version (strip leading `v` if provided, e.g., `v1.4.0` -> `1.4.0`).
   * Validate that the version matches Semantic Versioning: `^%d+%.%d+%.%d+$` (`MAJOR.MINOR.PATCH`).
   * Compare against current `VERSION` in `src/header.lua`: the new version must be strictly greater.

4. **Tag Non-Existence**:
   * Verify that the Git tag does not already exist:
     ```bash
     git rev-parse -q --verify "refs/tags/v<VERSION>"
     ```
   * If the tag exists, **abort immediately** with an error.

5. **Pre-Release Dev Test Suite**:
   * Run the test suite before any changes:
     ```bash
     lua test.lua --dev
     ```
   * **All tests must pass**. If any test fails, abort immediately.

---

## 2. Step-by-Step Release Protocol

### Step 1: Update Version in Code & Docs
1. **[`src/header.lua`](file:///home/stefan/Development/podscript/src/header.lua)**:
   * Update the `VERSION` constant to the target version:
     ```lua
     ---@build const:
     global VERSION<const> = "<VERSION>"
     ```
2. **[`README.md`](file:///home/stefan/Development/podscript/README.md)** & Documentation:
   * Inspect `README.md` and `USAGE.md` for any hardcoded version strings or example outputs and update them if present.

### Step 2: Finalize Changelog (`CHANGELOG.md`)
1. In [`CHANGELOG.md`](file:///home/stefan/Development/podscript/CHANGELOG.md):
   * Locate the top `## [Unreleased]` section.
   * Replace `## [Unreleased]` directly with:
     ```markdown
     ## [<VERSION>] - <YYYY-MM-DD>
     ```
     *(Use current date in ISO format `YYYY-MM-DD`).*
   * **Do NOT create an empty `## [Unreleased]` section** above it.

### Step 3: Compile Release Build
1. Build the standalone release script with the `--release` flag:
   ```bash
   lua build.lua --release
   ```
2. Verify that [`pods.lua`](file:///home/stefan/Development/podscript/pods.lua) contains the clean build metadata:
   * Inspect lines 30–35 of `pods.lua`.
   * Confirm `local VERSION <const> = "<VERSION>"` is present.
   * Confirm `local BUILD <const> = "<count>.<hash>"` does **NOT** contain `.dev`.

### Step 4: Execute Full Test Suites
Run both development and release test suites:
```bash
lua test.lua --dev && lua test.lua
```
* **Every test in both modes must pass with 0 errors**.
* If any test fails, do not proceed to committing.

### Step 5: Smoke Test Release Banner
Verify that the compiled CLI banner displays the clean version:
```bash
lua pods.lua help | head -n 1
```
* Expected output format: `PodScript v<VERSION>+<count>.<hash>` (e.g. `PodScript v1.4.0+146.fe9986c`).
* Must **not** contain `.dev`.

### Step 6: Git Staging, Commit & Tagging
1. Check changed files:
   ```bash
   git status --short
   ```
   * Only the expected release files must be modified:
     - `src/header.lua`
     - `pods.lua`
     - `CHANGELOG.md`
     - `README.md` (if documentation updated)
2. Stage modified files:
   ```bash
   git add src/header.lua pods.lua CHANGELOG.md
   # Include README.md if modified
   ```
3. Commit the release:
   ```bash
   git commit -m "Release v<VERSION>"
   ```
4. Create an annotated Git tag:
   ```bash
   git tag -a "v<VERSION>" -m "Release v<VERSION>"
   ```
5. Verify tag and commit:
   ```bash
   git tag -n -l "v<VERSION>"
   git log -1 --stat
   ```

---

## 3. Safe Rollback Procedure

If any failure occurs during Steps 1 through 5 (e.g., test failure or build error), abort the release and restore the workspace to a pristine state:
```bash
git checkout -- src/header.lua pods.lua CHANGELOG.md README.md
```
Report the failure reason clearly to the user without leaving partial modifications.
