---
id: PSP-005
title: Architectural Evaluation: Centralized Context vs. Parameter Passing
status: concept
type: architecture
created: 2026-09-25
updated: 2026-09-26
---

# PSP-005: Architectural Evaluation: Centralized Context vs. Parameter Passing

## 1. Summary & Motivation
PodScript currently passes a mutable `registry` table (`config`, `flags`, `parameters`, `config_full_path`) explicitly across mode handlers, config loaders, and validators. Investigating whether a centralized singleton context (`context.lua`) simplifies function signatures and improves ergonomics without compromising test isolation.

## 2. Goals & Non-Goals
* **Goals:**
    * Evaluate trade-offs between explicit parameter passing and an application-lifetime context module.
    * Establish an architecture that preserves 100% test suite isolation in `test.lua`.
    * Keep core container and pod generators (`pod.lua`, `container.lua`) decoupled and pure.
* **Non-Goals:**
    * Introducing ad-hoc, untracked global variables across modules.
    * Altering the declarative recipe format.

## 3. Analysis & Trade-Offs

| Aspect | Parameter Passing (`registry`) | Centralized Module (`context.lua`) |
| :--- | :--- | :--- |
| **Signatures** | Redundant parameter threading across mode functions. | Clean, concise function signatures. |
| **Deep Callers** | Intermediate functions must forward `registry`. | Direct access via `context.get_config()`, etc. |
| **Test Runner Isolation** | **Safe:** New `registry` instance per invocation in `main()`. | **High Risk:** `test.lua` runs 50+ tests sequentially in the **same Lua process**. Requires strict `context.reset()` in `main()`. |
| **Unit Testability** | Pure functions; easily tested with mock tables. | Implicit state dependencies; tests must manage context. |
| **Project Rules** | Fully compliant with `AGENTS.md` ("Avoid globals"). | Must be declared `global context<const>` with encapsulated state. |

## 4. Technical Architecture & Recommendations
* **Core Rule:** Never use raw mutable globals.
* **Encapsulated Module:** If refactoring, create `src/pods/context.lua`:
    * Declared atop: `global context<const> = { ... }`.
    * Methods: `context.reset()`, `context.init(...)`, `context.get_config()`, `context.is_simulate()`.
* **Mandatory Reset:** Call `context.reset()` at the start of `main()` to guarantee test isolation.
* **Scope Boundary:** Restrict `context` access strictly to mode controllers (`mode_*.lua`). Keep `container.lua` and `pod.lua` pure.

## 5. Decision & Next Steps
* Keep current `registry` parameter passing until a dedicated refactoring phase.
* Prototype `context.lua` in an isolated branch/feature if signature verbosity becomes a blocker.

## 6. Work Log & Decisions
* **2026-09-25:** Architectural analysis conducted and documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-005-central-context-eval.md`.
