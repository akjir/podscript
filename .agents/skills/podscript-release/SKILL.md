---
name: podscript-release
description: >-
  Official release workflow for PodScript. Validates repo state, runs tests, bumps versions, updates CHANGELOG.md, builds release, and creates Git tags.
---

# PodScript Release Workflow

Run this workflow when instructed to release a version (e.g., "Release version 1.4.0"). Every step must pass. If any step fails, stop and run the rollback procedure.

## 1. Pre-Flight Checks
1. **Clean Tree:** Verify `git status --porcelain` is empty. If not, stop and ask the user to commit or stash changes.
2. **Branch:** Verify `git branch --show-current` is `main` (or the target release branch).
3. **Version:** Strip leading `v`. Verify `<VERSION>` matches `^%d+%.%d+%.%d+$` and is greater than `VERSION` in `src/pods/header.lua`.
4. **Tag:** Run `git rev-parse -q --verify "refs/tags/v<VERSION>"`. Stop if the tag exists.
5. **Dev Tests:** Run `./task test dev`. Verify 0 errors.

## 2. Release Steps
1. **Update Version:**
   * Set `global VERSION<const> = "<VERSION>"` in `src/pods/header.lua`.
   * Update version strings in `README.md` and `USAGE.md` if present.
2. **Update Changelog:**
   * In `CHANGELOG.md`, replace `## [Unreleased]` with `## [<VERSION>] - <YYYY-MM-DD>`.
   * Do **not** add an empty `## [Unreleased]` section.
3. **Build Release:**
   * Run `./task build --release`.
   * Verify `pods.lua` (lines 30–35) has `local VERSION <const> = "<VERSION>"` and `local BUILD <const>` without `.dev`.
4. **Run Tests:** Run `./task test`. Verify 0 errors.
5. **Check Banner:** Run `lua pods.lua help | head -n 1`. Verify it outputs `PodScript v<VERSION>+<count>.<hash>` without `.dev`.
6. **Commit & Tag:**
   * Run `git status --short`. Verify only `src/pods/header.lua`, `pods.lua`, `CHANGELOG.md`, and `README.md` changed.
   * Run:
     ```bash
     git add src/pods/header.lua pods.lua CHANGELOG.md README.md
     git commit -m "Release v<VERSION>"
     git tag -a "v<VERSION>" -m "Release v<VERSION>"
     ```
   * Verify with `git tag -n -l "v<VERSION>"` and `git log -1 --stat`.

## 3. Rollback Procedure
If any step fails before the commit, restore the workspace and report the error:
```bash
git checkout -- src/pods/header.lua pods.lua CHANGELOG.md README.md
```
