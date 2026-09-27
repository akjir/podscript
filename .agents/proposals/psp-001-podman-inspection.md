---
id: PSP-001
title: Running Containers Display & Granular Podman Inspection
status: review
type: feature
created: 2026-09-25
updated: 2026-09-27
---

# PSP-001: Running Containers Display & Granular Podman Inspection

## Part 1: Concept & Proposal

### 1.1 Summary
Providing direct inspection capabilities within PodScript for runtime state to keep workflow management self-contained.

### 1.2 Motivation
PodScript manages recipes, pods, and container lifecycles declaratively, but inspecting runtime state (running status, health checks, exposed ports, uptime) currently forces the user to exit PodScript and run manual `podman ps` commands. Providing direct inspection capabilities within PodScript keeps workflow management self-contained.

### 1.3 Goals & Non-Goals
* **Goals:**
    * Query and display running containers and pod associations directly through PodScript.
    * Parse and present container statuses cleanly without external dependencies.
    * Support optional filtering by pod name or listing all PodScript-managed containers.
    * Support listing unmanaged/external containers alongside managed ones via an `--all` flag.
    * Provide critical container health metrics: Health Check status, Exit Codes, and Restart Counts.
    * Visually group or map containers back to their respective PodScript recipes/pods.
* **Non-Goals:**
    * Building a full-blown interactive TUI or process monitoring tool.
    * Managing non-Podman container runtimes (Docker, nerdctl).

### 1.4 Description
* **CLI Command:**
    * `pods status [TARGETS] [--full] [--all]`
    * Because `status` is implemented as an action in the `default` mode, the command structure adheres to the required `pods [MODE] [ACTION] [TARGETS]` format (where the `default` mode can be omitted).
    * If `status` is invoked without any targets, the status of *all* managed containers will be displayed (whether running or not).
    * If targets are provided (e.g., `pods status pod1 @stack`), their status is checked. If the targets are not running, the output will explicitly list those individual containers as not running.
    * If the `--all` flag is passed, the output will include all containers known to Podman, acting as a PodScript-templated version of `podman ps`.
* **Output:**
    * Dependency-free structured table on stdout.
    * **Default Output:** Container ID, Created, Status (including Health & Exit Code), Restart Count, Names, and Pod Association.
    * **`--full` Output:** Includes all default fields plus Image, Command, and Ports.

### 1.5 Alternatives
*(None documented yet. Sticking with direct `podman` command execution and standard parsing.)*

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* **Affected Files:**
    * `src/pods/mode_default.lua`:
        * Add `"status"` to allowed actions validation.
        * Allow empty targets strictly when `action == "status"`.
        * Intercept the `"status"` action to bypass the per-recipe loop and call `pod__status(context)` once.
    * `src/pods/pod.lua`:
        * Implement `pod__status(context)` to execute the query, filter requested targets, and format output based on the `--full` flag.
    * `src/pods/system.lua`:
        * Implement `system.exec_capture(command)` to use `io.popen` and `handle:lines()` for returning the STDOUT string lines as a table.

### 2.2 Schema & Syntax Changes
No changes to `config.lua` or recipe schemas are required, as this primarily queries runtime state rather than configuration.

### 2.3 Implementation Details
* **Target Filtering:**
    * If `context.targets` is empty and `--all` is not passed, resolve all known managed recipes by iterating over `context.config.recipes.groups`.
    * Cross-reference the parsed `podman` output against the requested (or resolved) recipes' containers (`recipe.containers`). Only display containers that match these managed recipes.
    * Explicitly print an entry for any target container that is *not* found in the podman output (meaning it's not running or doesn't exist).
    * **If `--all` is passed (`context.flags.all`):** Bypass the managed-only filter and display all containers returned by Podman (alongside explicitly requested targets, if any).
* **Output Formatting (`--full` vs default):**
    * Check `context.flags.full`.
    * Default output columns: `ID`, `CREATED`, `STATUS`, `RESTARTS`, `NAMES`, `POD`.
    * Full output columns: `ID`, `IMAGE`, `COMMAND`, `CREATED`, `STATUS`, `RESTARTS`, `PORTS`, `NAMES`, `POD`.
* **Query Execution:**
    * Call the new `system.exec_capture` querying `podman ps -a` (to include stopped containers for exit codes).
    * **Formatting:** Use Go Templates with a pipe (`|`) delimiter:
      `podman ps -a --format "{{.ID}}|{{.Image}}|{{.Command}}|{{.CreatedAt}}|{{.Status}}|{{.Ports}}|{{.Names}}|{{.PodName}}|{{.Restarts}}"`
* **Parsing:**
    * Iterate over the captured lines, split each line natively in Lua using `string.split(line, "|")`, mapping them to container tables. This entirely avoids JSON parser dependencies.

### 2.4 Testing Strategy
* Mock podman execution output in test suites.
* Verify empty list, running containers, unhealthy containers, stopped containers.
* Verify correct behavior when no targets are specified (should list all managed containers).
* Verify correct behavior when `--all` is specified (should list unmanaged containers too).
* Test suite in `tests/pods/suite_017_action_status.lua` (or similar).

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [x] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [x] Create test stubs in `tests/pods/suite_017_action_status.lua` (covering `--full` and `--all`).
- [x] Implement core logic for parsing `podman ps` output and `system.exec_capture`.
- [x] Implement action dispatch in `src/pods/mode_default.lua`.
- [x] Build release (`lua build.lua`).
- [x] Run full test suites (`lua test.lua --dev` & `lua test.lua`) and verify 100% pass.
- [x] Update `USAGE.md` with new CLI syntax.
- [x] Add entry to `CHANGELOG.md`.
- [x] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [ ] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-001-podman-inspection.md`.
* **2026-09-27:** Implemented `pod__status`, test suite, updated documentation.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
