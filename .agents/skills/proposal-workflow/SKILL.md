---
name: proposal-workflow
description: >-
  Manage, specify, and track proposals in .agents/proposals/. Covers proposal lifecycle stages, 3-part specification template (Concept, Design, Implementation), and TDD transitions.
---

# Proposal Management Workflow

## 1. Directory Structure
* Location: `.agents/proposals/`
* Master Board: `.agents/proposals/BOARD.md` (summary table with IDs, titles, types, and statuses).
* Template: `.agents/proposals/TEMPLATE.md` (3-part structure).
* Files: `psp-XXX-<slug>.md` (e.g. `psp-001-podman-inspection.md`).

## 2. Lifecycle Stages
* **`concept`:** High-level idea, motivation, and JEP-style proposal (Part 1).
* **`planned`:** Formal technical specification agreed: architecture, schema, and tests defined (Part 2).
* **`in-progress`:** Active development following `podscript-dev-workflow` (TDD first). Pre-requisite: baseline test suites (`lua test.lua --dev` & `lua test.lua`) verified green before making changes. Tasks tracked in Part 3.
* **`review`:** Implementation complete. Verification: dev tests (`lua test.lua --dev`), release build (`lua build.lua`), and release tests (`lua test.lua`) 100% green; changelog and docs prepared. Awaits manual user review and approval.
* **`completed`:** Manually reviewed, approved, and merged. Retained permanently as a historical architectural record. If later superseded or reversed by new architecture, DO NOT change status; instead, prepend a `> [!NOTE]` "Historical Record" block explaining the divergence.
* **`rejected`:** Dismissed or superseded; rationale documented in spec.

## 3. Creating a Proposal
1. **Assign ID:** Next sequential 3-digit number (e.g. `PSP-015`).
2. **Create Spec:** Copy `.agents/proposals/TEMPLATE.md` to `.agents/proposals/psp-XXX-<slug>.md`.
3. **Fill Schema (Part 1 & 2):** Complete frontmatter and all sections in Part 1 (Concept) and Part 2 (Technical Design).
4. **Update Board:** Add row to `.agents/proposals/BOARD.md`.

## 4. Development & Completion Cycle
1. **Promote to `planned`:** Align with user on architecture and syntax.
2. **Promote to `in-progress`:** Begin implementation. Use Task Breakdown in Part 3.1.
    * **Pre-Verification (Before):** Run baseline test suites (`lua test.lua --dev` and `lua test.lua`) to guarantee a 100% clean starting state before editing any code.
    * **Implementation:** Follow **`podscript-dev-workflow`** for TDD implementation, testing, and building. Check off tasks in Part 3.1.
    * **Living Document:** If implementation details, CLI syntax, or technical choices diverge from the original proposal during development (e.g., necessary corrections or better alternatives discovered during coding), the PSP document (Part 1 and Part 2) MUST be updated to accurately reflect the final, actual implementation.
3. **Promote to `review`:**
    * **Post-Verification (After):** Run `lua test.lua --dev`, execute release build (`lua build.lua`), and verify full release suite passes (`lua test.lua`).
    * **Documentation:** Update `CHANGELOG.md`, `USAGE.md` (see `update-documentation` skill), the CLI help menu, `.pods-completion.bash`, and the root templates (`config.lua`, `recipe.lua`) if syntax or schema changed.
    * **Update Status:** Set frontmatter `status: review` in the proposal spec and update `.agents/proposals/BOARD.md`.
    * **Request Approval:** Present deliverables to the user for manual inspection and verification. Never transition to `completed` autonomously.
4. **Promote to `completed`:**
    * **User Approval Required:** Advance to `completed` only after explicit manual approval from the user.
    * **Finalize:** Update frontmatter `status: completed` and update `.agents/proposals/BOARD.md`. Document delivered artifacts in Part 3.3.

## 5. Historical Pitfalls & Lessons Learned
To avoid repeating past mistakes, incorporate these learnings into your implementation and proposal drafting:
* **Test Isolation:** Avoid singletons or global state (e.g., a central `context.lua` singleton). Always rely on explicit parameter passing to guarantee test runner isolation and prevent cross-contamination.
* **Comprehensive Documentation Sync:** When removing, renaming, or migrating modes and flags, meticulously update all references. Check `USAGE.md` (examples, Modes Overview), `README.md` (remove dangling/broken markdown tables), `AGENTS.md` (update architecture and naming), and root templates (`config.lua`, `recipe.lua`).
* **Mock Configurations:** When refactoring core execution functions, ensure mock configurations in test suites don't trigger unwanted shell side-effects.
* **Changelog Diligence:** Skip `CHANGELOG.md` updates for internal test/dev/refactoring changes; it is strictly for user-facing changes.
* **Flag Scoping:** Explicitly separate action-specific flags (e.g., `--preview` for a prune action) from global flags (e.g., `--simulate`).
* **Naming Conventions:** Ensure strict adherence to established naming conventions (e.g., `mode_<name>__*` or `prefix__*`) throughout the implementation.

## 6. Token Efficiency & Agent Guidelines
* Always read `.agents/proposals/BOARD.md` first to inspect existing proposal statuses.
* Only load individual `psp-XXX-*.md` files when actively reviewing, planning, or working on that specific proposal.
* Never read all proposal files concurrently.
