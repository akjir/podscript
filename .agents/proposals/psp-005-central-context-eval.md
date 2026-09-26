---
id: PSP-005
title: Architectural Evaluation: Centralized Context vs. Parameter Passing
status: concept
type: architecture
created: 2026-09-25
updated: 2026-09-26
---

# PSP-005: Architectural Evaluation: Centralized Context vs. Parameter Passing

## Part 1: Concept & Proposal (JEP-Style)

### 1.1 Summary
PodScript currently passes a mutable `registry` table (`config`, `flags`, `parameters`, `config_full_path`) explicitly across mode handlers, config loaders, and validators. Investigating whether a centralized singleton context (`context.lua`) simplifies function signatures and improves ergonomics without compromising test isolation.

### 1.2 Motivation
Signature verbosity when passing the mutable `registry` table across multiple layers (mode handlers, config loaders, validators) can impact development velocity and readability. A centralized context module could simplify deep function signatures by providing direct access to configuration and state.

### 1.3 Goals & Non-Goals
* **Goals:**
    * Evaluate trade-offs between explicit parameter passing and an application-lifetime context module.
    * Establish an architecture that preserves 100% test suite isolation in `test.lua`.
    * Keep core container and pod generators (`pod.lua`, `container.lua`) decoupled and pure.
* **Non-Goals:**
    * Introducing ad-hoc, untracked global variables across modules.
    * Altering the declarative recipe format.

### 1.4 Description
Evaluate whether introducing an encapsulated singleton `context.lua` module is superior to explicit parameter passing. This includes comparing function signature verbosity, test runner isolation risks (since `test.lua` runs many tests sequentially in the same Lua process), and unit testability. 

The evaluation includes an analysis of trade-offs:

| Aspect | Parameter Passing (`registry`) | Centralized Module (`context.lua`) |
| :--- | :--- | :--- |
| **Signatures** | Redundant parameter threading across mode functions. | Clean, concise function signatures. |
| **Deep Callers** | Intermediate functions must forward `registry`. | Direct access via `context.get_config()`, etc. |
| **Test Runner Isolation** | **Safe:** New `registry` instance per invocation in `main()`. | **High Risk:** `test.lua` runs 50+ tests sequentially in the **same Lua process**. Requires strict `context.reset()` in `main()`. |
| **Unit Testability** | Pure functions; easily tested with mock tables. | Implicit state dependencies; tests must manage context. |
| **Project Rules** | Fully compliant with `AGENTS.md` ("Avoid globals"). | Must be declared `global context<const>` with encapsulated state. |

### 1.5 Alternatives
The current approach uses explicit parameter passing of a `registry` table. This evaluation weighs keeping the current explicit approach versus migrating to the centralized module.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
If implemented, this refactor would affect:
* `src/pods/main.lua` (would need a `context.reset()` invocation to maintain test isolation).
* `src/pods/mode_*.lua` (would access state through `context` rather than `registry` argument).
* A new `src/pods/context.lua` module.

### 2.2 Schema & Syntax Changes
No syntax or recipe schema changes. Internal data structures would transition from passing a `registry` parameter to utilizing `context` module methods.

### 2.3 Implementation Details
* **Core Rule:** Never use raw mutable globals.
* **Encapsulated Module:** If refactoring, create `src/pods/context.lua`:
    * Declared atop: `global context<const> = { ... }`.
    * Methods: `context.reset()`, `context.init(...)`, `context.get_config()`, `context.is_simulate()`.
* **Mandatory Reset:** Call `context.reset()` at the start of `main()` to guarantee test isolation.
* **Scope Boundary:** Restrict `context` access strictly to mode controllers (`mode_*.lua`). Keep `container.lua` and `pod.lua` pure.

### 2.4 Testing Strategy
Tests must rigorously verify that the context module maintains isolation:
* Ensure `context.reset()` thoroughly clears state.
* Since `tests/pods/test.lua` sequentially runs tests in a single Lua process, confirm there is no state leakage between mock test invocations.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Keep current `registry` parameter passing until a dedicated refactoring phase.
- [ ] Prototype `context.lua` in an isolated branch/feature if signature verbosity becomes a blocker.

### 3.2 Work Log & Decisions
* **2026-09-25:** Architectural analysis conducted and documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-005-central-context-eval.md` (and subsequently `.agents/proposals/psp-005-central-context-eval.md`).
* **Decision:** Keep current `registry` parameter passing until a dedicated refactoring phase. Prototype `context.lua` in an isolated branch/feature if signature verbosity becomes a blocker.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
