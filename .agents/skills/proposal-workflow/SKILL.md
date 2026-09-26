---
name: proposal-workflow
description: >-
  Manage, specify, and track proposals in .agents/proposals/. Covers proposal lifecycle stages, 3-part specification template (Concept, Design, Implementation), and TDD transitions.
---

# Proposal Management Workflow

## 1. Directory Structure
* Location: `.agents/proposals/`
* Master Board: `.agents/proposals/README.md` (summary table with IDs, titles, types, and statuses).
* Template: `.agents/proposals/TEMPLATE.md` (3-part structure).
* Files: `psp-XXX-<slug>.md` (e.g. `psp-001-podman-inspection.md`).

## 2. Lifecycle Stages
* **`concept`:** High-level idea, motivation, and JEP-style proposal (Part 1).
* **`planned`:** Formal technical specification agreed: architecture, schema, and tests defined (Part 2).
* **`in-progress`:** Under active development following `podscript-dev-workflow` (TDD first). Tasks checked off in Part 3.
* **`review`:** Tests green (`test.lua --dev` & `test.lua`); changelog and docs prepared.
* **`completed`:** Merged and verified; retained in board as permanent architectural record. Delivered artifacts logged.
* **`rejected`:** Dismissed or superseded; rationale documented in spec.

## 3. Creating a Proposal
1. **Assign ID:** Next sequential 3-digit number (e.g. `PSP-015`).
2. **Create Spec:** Copy `.agents/proposals/TEMPLATE.md` to `.agents/proposals/psp-XXX-<slug>.md`.
3. **Fill Schema (Part 1 & 2):** Complete frontmatter and all sections in Part 1 (Concept) and Part 2 (Technical Design).
4. **Update Board:** Add row to `.agents/proposals/README.md`.

## 4. Development & Completion Cycle
1. **Promote to `planned`:** Align with user on architecture and syntax.
2. **Promote to `in-progress`:** Begin implementation. Use Task Breakdown in Part 3.1.
    * Follow **`podscript-dev-workflow`** for TDD implementation, testing, and building.
3. **Promote to `review`:** Update `CHANGELOG.md` and `USAGE.md` (see `update-documentation` skill).
4. **Promote to `completed`:** Update frontmatter `status: completed` and update `.agents/proposals/README.md`. Document delivered artifacts in Part 3.3.

## 5. Token Efficiency & Agent Guidelines
* Always read `.agents/proposals/README.md` first to inspect existing proposal statuses.
* Only load individual `psp-XXX-*.md` files when actively reviewing, planning, or working on that specific proposal.
* Never read all proposal files concurrently.
