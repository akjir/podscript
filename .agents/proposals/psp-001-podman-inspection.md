---
id: PSP-001
title: Running Containers Display & Granular Podman Inspection
status: concept
type: feature
created: 2026-09-25
updated: 2026-09-26
---

# PSP-001: Running Containers Display & Granular Podman Inspection

## 1. Summary & Motivation
PodScript manages recipes, pods, and container lifecycles declaratively, but inspecting runtime state (running status, health checks, exposed ports, uptime) currently forces the user to exit PodScript and run manual `podman ps` commands. Providing direct inspection capabilities within PodScript keeps workflow management self-contained.

## 2. Goals & Non-Goals
* **Goals:**
    * Query and display running containers and pod associations directly through PodScript.
    * Parse and present container statuses cleanly without external dependencies.
    * Support optional filtering by pod name or listing all PodScript-managed containers.
* **Non-Goals:**
    * Building a full-blown interactive TUI or process monitoring tool.
    * Managing non-Podman container runtimes (Docker, nerdctl).

## 3. Specification & CLI Syntax
* **CLI Command:**
    * `pods status [NAME]` or `pods ps [NAME]`
* **Output:**
    * Dependency-free structured table on stdout (Pod, Container Name, Status/Health, Ports, Uptime).

## 4. Technical Architecture
* **Query Execution:**
    * Use `system.exec` or `io.popen` querying `podman ps --format "{{json .}}"` or `podman pod ps --format "{{json .}}"`.
* **Parsing & Formatting:**
    * Pure Lua parser in `src/pods/utilities.lua` or dedicated `src/pods/system.lua` helper.
    * Adhere to zero-dependency rule: no external JSON libraries; parse standard line format or key fields.
* **Affected Files:**
    * `src/pods/main.lua` (new mode/subcommand dispatch)
    * `src/pods/mode_status.lua` or `src/pods/mode_command.lua`
    * `src/pods/system.lua`

## 5. Test Strategy (TDD)
* Mock podman execution output in test suites.
* Verify empty list, running containers, unhealthy containers, stopped containers.
* Test suite in `tests/pods/suite_017_mode_status.lua`.

## 6. Work Log & Decisions
* **2026-09-25:** Initial concept documented in `DEVELOPMENT.md`.
* **2026-09-26:** Migrated to `.agents/features/psp-001-podman-inspection.md`.
