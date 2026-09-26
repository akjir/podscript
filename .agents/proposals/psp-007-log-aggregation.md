---
id: PSP-007
title: Log Aggregation and Tailing (`logs` mode)
status: concept
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-007: Log Aggregation and Tailing (`logs` mode)

## 1. Summary & Motivation
PodScript currently lacks a native way to view or tail logs for containers managed by a recipe. Users must manually construct `podman pod logs` or `podman logs` commands. Adding a dedicated `logs` mode will streamline debugging and monitoring by wrapping `podman pod logs` with PodScript's configuration and targeting awareness, automatically enforcing coloring and container names for better readability.

## 2. Goals & Non-Goals
* **Goals:**
  * Introduce a `logs` mode to fetch and tail logs for a given recipe's pod.
  * Support common logging flags: `--follow` (`-f`), `--tail`, `--since`, `--until`, and `--container` (`-c`).
  * Integrate with the existing `simulate` mode to preview the `podman pod logs` command.
  * Always pass `--color` and `--names` (`-n`) to Podman natively to ensure readable, distinguishable log output per container.
* **Non-Goals:**
  * Aggregating logs across multiple recipes or recipe groups simultaneously (restricted to one recipe per `logs` command to keep it simple and avoid interleaved pod logs).
  * Formatting or parsing logs within Lua (Podman handles the output streams directly).
  * Supporting remote log aggregation (e.g., syslog, journald) directly through PodScript logic.

## 3. Specification & CLI Syntax
* **Syntax:** `pods logs [OPTIONS] <recipe>`
* **Options:**
  * `-f`, `--follow`: Follow log output.
  * `-t`, `--tail <n>`: Output the specified number of lines at the end of the logs.
  * `--since <timestamp>`: Show logs since timestamp.
  * `--until <timestamp>`: Show logs until timestamp.
  * `-c`, `--container <name|index>`: Filter logs by a specific container defined in the recipe. If an index is provided (e.g., `1`), it resolves to that container's absolute name. If a relative name is provided (e.g., `*app`), it resolves to `<pod_name>-app`.
* **Execution:**
  * The command resolves the specified recipe to extract the `pod.name`.
  * It translates the options into a Podman command: `podman pod logs -n --color [user_options] <pod_name>`.
  * Uses blocking execution (e.g., `os.execute`) to stream `stdout` and `stderr` directly to the terminal.
* **Simulation:**
  * `pods simulate logs [OPTIONS] <recipe>` prints the resolved Podman command instead of executing it.
* **Output & Exit Codes:**
  * Exits with the exit code returned by the underlying Podman process.

## 4. Technical Architecture
* **Affected Files:**
  * `src/pods/mode_logs.lua` (New): Implements `mode_logs__execute(config, args)`.
  * `src/pods/main.lua`: Register the `logs` mode in the router.
  * `USAGE.md`: Document the new `logs` mode in the Modes Overview.
* **Implementation Details:**
  * The CLI argument parser in `mode_logs.lua` must safely extract the supported flags (`-f`, `--tail`, etc.) and identify the target recipe.
  * Container name resolution for the `-c` flag must replicate the logic used in `command` mode to resolve `*app` or numeric indices to absolute container names.
  * Strict Lua 5.5 rules (`global<const> *`) and PodScript style guidelines must be followed.

## 5. Test Strategy (TDD)
* **Test Suites:**
  * `tests/pods/mode_logs_test.lua`: Verify the command builder accurately maps PodScript flags to `podman pod logs` flags.
  * Validate container name resolution logic (e.g., `-c 1` -> `-c mypod-ctr1`, `-c *app` -> `-c mypod-app`).
  * Verify edge case option parsing (e.g., `--follow`, `--tail=50`, `--since=1h`).
  * Validate simulation mode output format.
* **Edge Cases & Failure Modes:**
  * Missing or invalid recipe name (should exit with clear error).
  * Providing multiple recipe targets (should either error or gracefully use only the first).
  * Providing an invalid container index or name for `-c` (should exit with clear error).

## 6. Work Log & Decisions
* **2026-09-26:** Initial concept specification created. Enforced `--color` and `--names` by default for improved UX over raw Podman defaults.
