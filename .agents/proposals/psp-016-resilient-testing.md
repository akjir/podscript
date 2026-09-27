---
id: PSP-016
title: Resilient and Intelligent Testing Framework
status: concept
type: architecture
created: 2026-09-27
updated: 2026-09-27
---

# PSP-016: Resilient and Intelligent Testing Framework

## Part 1: Concept & Proposal

### 1.1 Summary
A comprehensive redesign of the `test.lua` testing framework to decouple test expectations from exact runtime line indices and execution side-effects, while drastically improving developer and AI agent experience via log provenance, fuzzy matching, smart diffing, and unit test isolation.

### 1.2 Motivation
Currently, the testing framework asserts that specific log outputs appear at exact line indices in an `output_stack`. Any structural change in verbosity, execution timing, or order of debug logs shifts these indices, causing cascading false-positive failures across the entire test suite. For instance, the PSP-005 refactoring shifted logs by two lines, which caused 172 tests to fail despite the business logic remaining perfectly intact. 

Furthermore, when tests fail, the output lacks context (where did a log originate?), stops at the first expectation mismatch (hiding other failures), and provides massive stack traces that flood an AI agent's context window. Finally, tests are currently heavily integrated (E2E via `main()`), making isolated logic testing difficult.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Eliminate strict line index assertions in favor of logic-based expectations (`contains`, `sequence`).
  * Embed log provenance (file and line number) into output stack traces.
  * Prevent premature test bailout (capture all expectation failures per test).
  * Introduce JSON output reporting and grouped failure summaries to optimize AI context.
  * Support isolated unit tests without invoking the full E2E `main()` CLI lifecycle.
* **Non-Goals:**
  * Replacing the custom Lua test framework with an external testing library (violates the zero external dependency rule).
  * Modifying existing business logic inside `src/pods/` (this proposal is strictly test infrastructure).

### 1.4 Description
The test execution framework (`test.lua`) will be refactored. Test definitions in `suite_*.lua` files will shift from array-index based expectations (`{ index, "string" }`) to logic-based assertions (`contains`, `matches`, `not_contains`, `sequence`). 
The `print_to_stack` override will utilize `debug.getinfo()` to automatically prefix captured logs with their origin file and line number. 
A new CLI flag `--json` will format the test output into structured JSON for automated consumption. The runner will capture all expectation failures for a given test before aborting, presenting a complete diff and grouped failure summaries at the end. Finally, a new `execute_unit_test` API will be provided to invoke specific internal functions with mocked `context` objects for true unit testing.

### 1.5 Alternatives
* **Keep Exact Index Matching but build migration scripts:** We could build a script that auto-updates indices when code changes. However, this still breaks tests on trivial changes and treats symptoms rather than the root architectural issue.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `test.lua`: Refactored core execution loop (`execute_mode_test`), log capture (`print_to_stack`), and output reporting.
* `tests/pods/suite_*.lua`: Refactored expectation definitions.

### 2.2 Schema & Syntax Changes
Test cases will adopt a new structure for expectations:
```lua
expectations = {
    contains = { "ERROR: Recipe 'invalid' not found in config." },
    sequence = { "DEBUG: Targets", "DEBUG: Untangled", "DEBUG: Default mode is used." },
    not_contains = { "WARNING: Command has no description." },
    exact = { [5] = "INFO: Simulate mode is active." } -- Legacy fallback support
}
```

### 2.3 Implementation Details
1. **Log Provenance:** Update `print_to_stack` in `test.lua` to call `debug.getinfo(3)` and track callers (e.g., `[main.lua:148] DEBUG: ...`).
2. **Assertion Engine:** Modify `execute_mode_test` to process the new expectation tables.
   * `contains`: Checks if a string exists anywhere in `output_stack`.
   * `sequence`: Checks relative order of a list of strings, verifying they appear sequentially (though not necessarily adjacently).
   * `exact`: Retains legacy exact index matching.
3. **Failure Accumulation:** Run all assertions for a test. If failures occur, print a unified diff with visual indicators (e.g., `Hint: Expected string missing at line 5, found at line 4`).
4. **Grouped Summaries:** Maintain a table of failure reasons. At the end of execution, print summaries like `12 tests failed missing string: 'Simulate mode'`.
5. **Unit Testing API:** Provide `execute_unit_test(func, ...)` in `test.lua` that suppresses global side-effects and tests function return values directly.
6. **Migration:** Write a Lua migration script to convert existing tests from `{ index, "string" }` to `sequence = { ... }`.

### 2.4 Testing Strategy
* Create a dedicated `suite_999_test_framework.lua` that executes dummy functions and asserts the new framework correctly identifies passes, failures, missing sequences, and exact line mismatches.
* All existing 172 tests must continue to pass using the new `sequence` schema.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [ ] Implement log provenance (`debug.getinfo`) in `test.lua`.
- [ ] Implement `contains`, `sequence`, and `exact` assertion engines in `execute_mode_test`.
- [ ] Implement failure accumulation, diffing, and grouped summaries.
- [ ] Implement `--json` flag and unit testing API.
- [ ] Create `suite_999_test_framework.lua` to test the framework itself.
- [ ] Migrate all existing `suite_*.lua` files to the new `sequence` expectation schema.
- [ ] Build release (`lua build.lua`).
- [ ] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [ ] Update `CHANGELOG.md`.
- [ ] Set status to `review` and request manual user review and approval.
- [ ] Manual approval received; set status to `completed` and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-09-27:** Initial concept drafted based on painful debugging experience during PSP-005 integration.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
