---
name: proposal-workflow
description: >-
  Manage, specify, and track proposals in .agents/proposals/. Covers feature lifecycle stages, specification template, and TDD transitions.
---

# Proposal Management Workflow

## 1. Directory Structure
* Location: `.agents/proposals/`
* Master Board: `.agents/proposals/README.md` (summary table with IDs, titles, types, and statuses).
* Template: `.agents/proposals/TEMPLATE.md`.
* Files: `psp-XXX-<slug>.md` (e.g. `psp-001-podman-inspection.md`).

## 2. Lifecycle Stages
* **`concept`:** High-level idea, problem statement, and motivation.
* **`planned`:** Formal specification agreed: CLI syntax, technical architecture, and test cases defined.
* **`in-progress`:** Under active development following `podscript-dev-workflow` (TDD first).
* **`review`:** Tests green (`test.lua --dev` & `test.lua`); changelog and docs prepared.
* **`completed`:** Merged and verified; retained in board as permanent architectural record.
* **`rejected`:** Dismissed or superseded; rationale documented in spec.

## 3. Creating a Proposal
1. **Assign ID:** Next sequential 3-digit number (e.g. `PSP-007`).
2. **Create Spec:** Copy `.agents/proposals/TEMPLATE.md` to `.agents/proposals/psp-XXX-<slug>.md`.
3. **Fill Schema:** Complete frontmatter and markdown sections (Summary, Goals, Syntax, Architecture, Test Strategy).
4. **Update Board:** Add row to `.agents/proposals/README.md`.

## 4. Development & Completion Cycle
1. **Promote to `planned`:** Align with user on architecture and syntax.
2. **Promote to `in-progress`:** Begin implementation.
    * Follow **`podscript-dev-workflow`**: write tests first in `tests/pods/`, implement in `src/pods/`.
    * Run tests: `lua test.lua --dev [testID]`.
    * Build: `lua build.lua` and verify `lua test.lua [testID]`.
3. **Promote to `review`:** Update `CHANGELOG.md` (Keep a Changelog, 6–15 words, past tense) and `USAGE.md` if CLI syntax changed.
4. **Promote to `completed`:** Update frontmatter `status: completed` and update `.agents/proposals/README.md`.

## 5. Token Efficiency & Agent Guidelines
* Always read `.agents/proposals/README.md` first to inspect existing proposal statuses.
* Only load individual `psp-XXX-*.md` files when actively reviewing, planning, or working on that specific proposal.
* Never read all proposal files concurrently.
