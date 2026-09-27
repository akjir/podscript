---
id: PSP-016
title: Resilient and Intelligent Testing Framework
status: completed
status: completed
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
  * Eliminate strict line index assertions entirely in favor of logic-based expectations (`contains`, `sequence`, `not_contains`, `matches`, `count`).
  * Embed log provenance (file and line number) into output stack traces.
  * Prevent premature test bailout (capture all expectation failures per test).
  * Introduce JSON output reporting and grouped failure summaries to optimize AI context.
  * Add developer ergonomics: `--fail-fast` flag and execution time measurement.
  * Support isolated unit tests without invoking the full E2E `main()` CLI lifecycle.
* **Non-Goals:**
  * Replacing the custom Lua test framework with an external testing library (violates the zero external dependency rule).
  * Modifying existing business logic inside `src/pods/` (this proposal is strictly test infrastructure).
  * Maintaining legacy fallback support for exact indices.

### 1.4 Description
The test execution framework (`test.lua`) will be refactored. Test definitions in `suite_*.lua` files will shift from array-index based expectations to logic-based assertions (`contains`, `sequence`, `not_contains`, `matches`, `count`).
The legacy `exact` matching will be completely removed to force robust testing. 
The `print_to_stack` override will utilize `debug.getinfo()` to automatically prefix captured logs with their origin file and line number. 
New CLI flags (`--json`, `--fail-fast`) will be added to the existing CLI structure without breaking current execution modes. The runner will capture all expectation failures for a given test before aborting, presenting a grouped failure summary at the end. Finally, execution time tracking and a new `execute_unit_test` API will be provided.

### 1.5 Alternatives
* **Keep Exact Index Matching but build migration scripts:** We could build a script that auto-updates indices when code changes. However, this still breaks tests on trivial changes and treats symptoms rather than the root architectural issue.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `test.lua`: Refactored core execution loop (`execute_mode_test`), log capture (`print_to_stack`), argument parsing, and output reporting.
* `tests/pods/suite_*.lua`: Refactored expectation definitions.
* `USAGE.md` & `README.md`: Documentation for new CLI test flags (`--json`, `--fail-fast`).
* `.agents/skills/podscript-dev-workflow/SKILL.md`: Update test workflow documentation regarding the new resilient testing schema and usage.

### 2.2 Schema & Syntax Changes
Test cases will adopt a new structure for expectations. The legacy `exact` schema is removed.
```lua
expectations = {
    contains = { "ERROR: Recipe 'invalid' not found in config." },
    sequence = { "DEBUG: Targets", "DEBUG: Untangled", "DEBUG: Default mode is used." },
    not_contains = { "WARNING: Command has no description." },
    matches = { "^%[.*%] INFO:.*" }, -- Lua patterns / Regex support
    count = { ["DEBUG: Step executed"] = 3 } -- Ensures exact occurrence count
}
```

### 2.3 Implementation Details

1. **CLI Argument Parsing & State Management:**
   * Extend the `arg` loop to detect `--json` (sets global `use_json = true`) and `--fail-fast` (sets global `fail_fast = true`).
   * Retain the logic where any argument not starting with `--` is treated as `single_test_name` (handling groups like `001` or single tests `00101`).

2. **JSON Output Reporting (`--json`):**
   * **Purpose:** Plain text console output is hard for CI pipelines and AI agents to parse. JSON provides a structured, predictable data format.
   * **Behavior:** When `--json` is active, standard interactive `print()` calls during test execution are suppressed.
   * **Implementation:** Test results (name, status, execution time, specific assertion errors, and the output stack for failed tests) are pushed into a global Lua table `test_report`. At the very end of `test.lua`, a lightweight, custom Lua-to-JSON serializer function (added directly to `test.lua` to maintain zero external dependencies) converts this table into a JSON string and prints it to `stdout` once.

3. **Log Provenance:**
   * **Purpose:** Instantly identify exactly which file and line produced a specific log output.
   * **Implementation:** Update `print_to_stack` to dynamically locate the caller. It loops through `debug.getinfo(level, "Sl")` starting from `level = 2` up to `6`. It skips any `short_src` that contains `log.lua` or `test.lua`. Once the real caller is found, it extracts the base filename via pattern matching (e.g., `([^/\\]+)$`) and prepends `[filename.lua:line] ` to the captured log string in `output_stack`.

4. **Assertion Engine:**
   Modify `execute_mode_test` to process the new expectation tables. It evaluates all keys present:
   * `contains`: Loops over `output_stack` using `string.find(line, expected, 1, true)`.
   * `sequence`: Maintains a `current_idx`. Finds the first string, updates `current_idx` to the found line, then searches for the next string starting from `current_idx`. Fails if the sequence is broken.
   * `not_contains`: Fails if `string.find(line, not_expected, 1, true)` is found anywhere in the stack.
   * `matches`: Uses `string.find(line, pattern, 1, false)` to evaluate Lua patterns (Regex equivalent).
   * `count`: Loops over `output_stack`, increments a counter for every match, and asserts it equals the expected integer.

5. **Failure Accumulation:**
   * **Purpose:** Show all reasons a test failed, rather than aborting on the first mismatch.
   * **Implementation:** Instead of returning `false` on the first error, `execute_mode_test` collects error descriptions into a `local errors = {}` table. After evaluating all assertions, if `#errors > 0`, it prints all collected errors for that test along with the `output_stack`, then returns false.

6. **Grouped Summaries & Timings:**
   * **Summaries:** A global table `failure_summaries = {}` tracks reasons. In the main loop, if a test fails, we increment `failure_summaries[error_string]`. At the end of execution, print a grouped summary (e.g., `12x : Missing in sequence: 'DEBUG: Targets'`).
   * **Timings:** Add `local start_time = os.clock()` at the beginning of `test.lua` and print the elapsed time at the end (e.g., `All tests passed in 0.45s`).

7. **Fail Fast (`--fail-fast`):**
   * **Purpose:** Save time and context window space when developing by aborting immediately upon the first error.
   * **Implementation:** In the test suite execution loops, immediately after `execute_test` returns, evaluate `if fail_fast and tests_count_failed > 0 then break end` to halt the runner.

8. **Unit Testing API (`execute_unit_test`):**
   * **Purpose:** Test isolated functions without the heavy side-effects of invoking `main(args)`.
   * **Implementation:** A new function `execute_unit_test(test_code, test_table)`. It clears `output_stack`, uses `pcall` to safely invoke `test_table.run(unpack(test_table.args))` (catching crashes), evaluates the return value against `test_table.expected`, and finally runs the logic assertion engine against the `output_stack`.

9. **Migration Script:**
   * Write a temporary Lua script (e.g., `scripts/migrate_tests.lua`) that reads all `tests/pods/suite_*.lua` files, finds the legacy `expectations = { { 1, "..." }, { 2, "..." } }`, and rewrites them to the new `sequence = { "...", "..." }` syntax using file I/O operations.

10. **Self-Test Engine API:**
    * **Purpose:** Allow the test framework to test its own failure identification capabilities without breaking the runner or requiring complex subprocess parsing (like `--self-test`).
    * **Implementation:** Decouple `evaluate_assertions` in `test.lua` from the global `output_stack` by allowing an optional `custom_stack` parameter. Expose the function globally via `_G.__TEST_FRAMEWORK = { evaluate_assertions = evaluate_assertions }`. This allows tests in `suite_999_test_framework.lua` to pass mock strings directly into the engine and verify it returns expected error strings for missing sequences, bad counts, etc.

10. **Self-Test Engine API:**
    * **Purpose:** Allow the test framework to test its own failure identification capabilities without breaking the runner or requiring complex subprocess parsing (like `--self-test`).
    * **Implementation:** Decouple `evaluate_assertions` in `test.lua` from the global `output_stack` by allowing an optional `custom_stack` parameter. Expose the function globally via `_G.__TEST_FRAMEWORK = { evaluate_assertions = evaluate_assertions }`. This allows tests in `suite_999_test_framework.lua` to pass mock strings directly into the engine and verify it returns expected error strings for missing sequences, bad counts, etc.

### 2.4 Testing Strategy
* Create a dedicated `suite_999_test_framework.lua` that executes dummy functions and asserts the new framework correctly identifies passes, failures, missing sequences, and matches.
* All existing 172 tests must continue to pass using the new `sequence`/`contains` schemas.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [x] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [x] Implement CLI argument parsing enhancements (`--fail-fast`, `--json`).
- [x] Implement log provenance (`debug.getinfo` iteration) in `test.lua`.
- [x] Implement logic assertion engine (`contains`, `sequence`, `not_contains`, `matches`, `count`) and remove `exact`.
- [x] Implement failure accumulation, grouped summaries, and `os.clock()` execution time tracking.
- [x] Implement unit testing API using `pcall`.
- [x] Create `suite_999_test_framework.lua` to test the framework itself.
- [x] Migrate all existing `suite_*.lua` files to the new expectation schema (no legacy fallbacks).
- [x] Update documentation (`USAGE.md`, `README.md`) to reflect new CLI test flags.
- [x] Update development skills (`podscript-dev-workflow`) to document the new resilient testing assertions and usage.
- [x] Build release (`lua build.lua`).
- [x] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [x] Update `CHANGELOG.md` (Note: test framework changes omitted from CHANGELOG as per strict dev-workflow rules).
- [x] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [x] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-09-27:** Initial concept drafted based on painful debugging experience during PSP-005 integration.
* **2026-09-27:** Refined scope to completely remove legacy `exact` index matching. Added logic for `--fail-fast`, Lua pattern matching (`matches`), occurrence counting (`count`), and execution time measurements.
* **2026-09-27:** Rewrote `test.lua` completely to match logic assertion. Implemented log provenance, json output and executed Python migration script on all tests. Tests passed smoothly. Skipped CHANGELOG as per strict rules.
* **2026-09-27:** Decoupled `evaluate_assertions` and exposed via `_G.__TEST_FRAMEWORK` to allow internal framework self-testing in `suite_999`.
* **2026-09-27:** Rewrote `test.lua` completely to match logic assertion. Implemented log provenance, json output and executed Python migration script on all tests. Tests passed smoothly. Skipped CHANGELOG as per strict rules.
* **2026-09-27:** Decoupled `evaluate_assertions` and exposed via `_G.__TEST_FRAMEWORK` to allow internal framework self-testing in `suite_999`.

### 3.3 Delivered Artifacts
* `test.lua` (Completely refactored for logic-based assertions, `--json`, `--fail-fast`, log provenance, `execute_unit_test`)
* `tests/pods/suite_*.lua` (Migrated 170+ tests from exact assertions to sequence assertions)
* `tests/pods/suite_999_test_framework.lua` (New test suite for test.lua itself)
* `README.md` & `.agents/skills/podscript-dev-workflow/SKILL.md` (Updated)
* `scripts/migrate_tests.py` and `scripts/rewrite_test_lua.py` (Temporary scripts)
* `test.lua` (Completely refactored for logic-based assertions, `--json`, `--fail-fast`, log provenance, `execute_unit_test`)
* `tests/pods/suite_*.lua` (Migrated 170+ tests from exact assertions to sequence assertions)
* `tests/pods/suite_999_test_framework.lua` (New test suite for test.lua itself)
* `README.md` & `.agents/skills/podscript-dev-workflow/SKILL.md` (Updated)
* `scripts/migrate_tests.py` and `scripts/rewrite_test_lua.py` (Temporary scripts)
