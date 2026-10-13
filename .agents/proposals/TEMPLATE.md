---
id: PSP-XXX
title: Proposal Title
status: concept # concept | planned | in-progress | review | completed | rejected
type: feature # feature | enhancement | refactor | architecture
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# PSP-XXX: Proposal Title

## Part 1: Concept & Proposal

### 1.1 Summary
Write a one-paragraph summary of the proposal and its objective.

### 1.2 Motivation
Explain the problem and why the current implementation is insufficient.

### 1.3 Goals & Non-Goals
* **Goals:** List specific, measurable outcomes.
* **Non-Goals:** List excluded features to prevent scope creep.

### 1.4 Description
Describe the feature, user workflows, CLI syntax, and system behavior.

### 1.5 Alternatives
List alternative solutions and explain why you rejected them.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
List modified files in `src/pods/` or `src/pods-converter/` and their interactions.

### 2.2 Schema & Syntax Changes
Specify changes to `config.lua`, recipe schemas, or internal data structures.

### 2.3 Implementation Details
Specify function signatures, variable scopes, `global<const>` declarations, and Podman commands.
* **Note:** Pass parameters explicitly; do not use singletons or global state. Separate action flags (e.g., `--preview`) from global flags (e.g., `--simulate`).

### 2.4 Testing Strategy
Define TDD test cases in `tests/pods/` or `tests/pods-converter/` (edge cases, errors, rootless vs. root).
* **Note:** Mock shell commands to prevent unintended side effects.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Run `./task verify` to confirm a clean baseline.
- [ ] Add test stubs in `tests/pods/` or `tests/pods-converter/`.
- [ ] Implement logic in `src/pods/` or `src/pods-converter/` using `prefix__*` naming.
- [ ] Update Parts 1 and 2 if the implementation changes the design.
- [ ] Run `./task verify` to build and pass all dev and release tests.
- [ ] Follow **`update-documentation`** to update `USAGE.md`, `README.md`, CLI help, `.pods-completion.bash`, `config.lua`, `recipe.lua`, and `AGENTS.md` as applicable.
- [ ] Add a `CHANGELOG.md` entry (skip for internal, test, or refactoring changes).
- [ ] Set status to `review`, update `BOARD.md`, and request user approval.
- [ ] After user approval, set status to `completed`, update `BOARD.md`, and list delivered artifacts.

### 3.2 Work Log & Decisions
* **YYYY-MM-DD:** Drafted initial concept.

### 3.3 Delivered Artifacts
*(Complete upon approval)*
