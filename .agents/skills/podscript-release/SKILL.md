---
name: podscript-release
description: >-
  Official release workflow for PodScript. Validates repo state, runs tests, bumps versions, updates CHANGELOG.md, builds release, and creates Git tags.
---

# PodScript Release Workflow

Use whenever instructed to cut a release (e.g. "Release version 1.4.0"). Strictly gate-kept: each step must succeed before proceeding. Abort and rollback on any failure.

---

## 1. Pre-Flight Validation Checks
1. **Clean Working Tree:** `git status --porcelain` must be completely empty. If dirty, abort immediately and request user commit/stash.
2. **Branch Check:** `git branch --show-current` must be `main` (or designated release branch).
3. **SemVer & Monotonicity:** Strip leading `v` (e.g. `v1.4.0` -> `1.4.0`). Must match SemVer regex `^%d+%.%d+%.%d+$` and be strictly greater than `VERSION` in `src/pods/header.lua`.
4. **Tag Non-Existence:** `git rev-parse -q --verify "refs/tags/v<VERSION>"`. Abort if tag exists.
5. **Dev Tests:** `lua test.lua --dev` must pass with 0 errors.

---

## 2. Step-by-Step Release Protocol

### Step 1: Update Version in Code & Docs
* **`src/pods/header.lua`:** Update `VERSION` constant (`global VERSION<const> = "<VERSION>"` under `---@build const:`).
* **`README.md` & `USAGE.md`:** Update hardcoded version strings or example outputs if present.

### Step 2: Finalize Changelog (`CHANGELOG.md`)
* Replace top `## [Unreleased]` with `## [<VERSION>] - <YYYY-MM-DD>` (current ISO date).
* **Do NOT create an empty `## [Unreleased]` section** above it.

### Step 3: Compile Release Build
1. Build release script: `lua build.lua --release`
2. Verify `pods.lua` (lines 30–35):
   * `local VERSION <const> = "<VERSION>"` present.
   * `local BUILD <const> = "<count>.<hash>"` does **not** contain `.dev`.

### Step 4: Execute Full Test Suites
Run both test suites: `lua test.lua --dev && lua test.lua` (must pass with 0 errors).

### Step 5: Smoke Test Release Banner
Verify CLI banner: `lua pods.lua help | head -n 1`
* Must output `PodScript v<VERSION>+<count>.<hash>` without `.dev`.

### Step 6: Git Staging, Commit & Tagging
1. Verify changed files with `git status --short`. Only expected release files may be modified:
   * `src/pods/header.lua`, `pods.lua`, `CHANGELOG.md`, and `README.md` (if doc updated).
2. Stage, commit, and tag:
   ```bash
   git add src/pods/header.lua pods.lua CHANGELOG.md README.md
   git commit -m "Release v<VERSION>"
   git tag -a "v<VERSION>" -m "Release v<VERSION>"
   ```
3. Verify: `git tag -n -l "v<VERSION>"` and `git log -1 --stat`.

---

## 3. Safe Rollback Procedure
If any check or step fails before completion, abort and restore workspace:
```bash
git checkout -- src/pods/header.lua pods.lua CHANGELOG.md README.md
```
Report the failure reason clearly to the user.
