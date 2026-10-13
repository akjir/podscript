---
name: proposal-workflow
description: >-
  Manage, specify, and track proposals in .agents/proposals/. Covers proposal lifecycle stages, 3-part specification template (Concept, Design, Implementation), and TDD transitions.
---

# Proposal Management Workflow

## 1. Files & Structure
* **Directory:** `.agents/proposals/`
* **Board:** `.agents/proposals/BOARD.md` (table of IDs, titles, types, statuses)
* **Template:** `.agents/proposals/TEMPLATE.md`
* **Proposals:** `psp-XXX-<slug>.md` (e.g., `psp-001-podman-inspection.md`)

## 2. Lifecycle Stages
* **`concept`:** Define the idea and motivation (Part 1).
* **`planned`:** Agree on architecture, schema, and tests with the user (Part 2).
* **`in-progress`:** Run `./task verify` first. Implement with TDD per **`podscript-dev-workflow`**. Track tasks in Part 3.1. Update Parts 1 and 2 if the design changes during coding.
* **`review`:** Pass `./task verify`, sync `USAGE.md` and `README.md` per **`update-documentation`**, update templates/changelog, set `status: review`, update `BOARD.md`, and ask the user for approval. Never set `completed` without user approval.
* **`completed`:** After user approval, set `status: completed`, update `BOARD.md`, and record artifacts in Part 3.3. Keep completed proposals permanently. If superseded later, keep `status: completed` and add a `> [!NOTE]` block at the top.
* **`rejected`:** Document the rejection reason and set `status: rejected`.

## 3. Creating a Proposal
1. Pick the next 3-digit ID from `BOARD.md` (e.g., `PSP-015`).
2. Copy `TEMPLATE.md` to `psp-XXX-<slug>.md`.
3. Complete the frontmatter, Part 1, and Part 2.
4. Add the proposal to `BOARD.md`.

## 4. Implementation Rules
* **Isolate State:** Pass parameters explicitly; never use singletons or global state.
* **Scope Flags:** Separate action flags (e.g., `--preview`) from global flags (e.g., `--simulate`).
* **Mock Safely:** Prevent shell side effects in test mocks.
* **Sync Docs:** Follow **`update-documentation`** to update `USAGE.md`, `README.md`, CLI help, `.pods-completion.bash`, `config.lua`, `recipe.lua`, and `AGENTS.md` when syntax, schemas, or features change.

## 5. Token Efficiency
* Read `BOARD.md` first.
* Read only the specific `psp-XXX-*.md` file required for the active task. Never read all proposals at once.
