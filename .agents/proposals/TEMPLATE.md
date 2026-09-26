---
id: PSP-XXX
title: Proposal Title
status: concept # concept | planned | in-progress | review | completed | rejected
type: feature # feature | enhancement | refactor | architecture
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# PSP-XXX: Proposal Title

## 1. Summary & Motivation
Brief explanation of the problem, motivation, and user impact.

## 2. Goals & Non-Goals
* **Goals:** Specific deliverables and expected outcomes.
* **Non-Goals:** Explicitly excluded capabilities to prevent scope creep.

## 3. Specification & CLI Syntax
* Command syntax and flags (e.g. `pods <mode> ...`).
* Output formatting, stdout/stderr behavior, exit codes.
* Configuration or recipe schema additions.

## 4. Technical Architecture
* Affected modular source files in `src/pods/` or `src/pods-converter/`.
* Function signatures, dependency boundaries, strict Lua 5.5 rules (`global<const> *`).
* Podman commands and OS-level interactions.

## 5. Test Strategy (TDD)
* Required test suites in `tests/pods/` (e.g. mode tests, code tests).
* Edge cases, failure modes, rootless/elevated behaviors.

## 6. Work Log & Decisions
* **YYYY-MM-DD:** Initial concept created.
