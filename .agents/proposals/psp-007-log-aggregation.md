---
id: PSP-007
title: Log Aggregation and Tailing (`logs` mode)
status: review
type: feature
created: 2026-09-26
updated: 2026-09-28
---

# PSP-007: Log Aggregation and Tailing (`logs` mode)

## Part 1: Concept & Proposal

### 1.1 Summary
A proposal to introduce a dedicated `logs` mode to PodScript, enabling users to easily view and tail logs for containers managed by a recipe with built-in coloring and targeting awareness.

### 1.2 Motivation
PodScript currently lacks a native way to view or tail logs for containers managed by a recipe. Users must manually construct verbose `podman pod logs` or `podman logs` commands. Adding a dedicated `logs` mode streamlines debugging and monitoring by wrapping these Podman commands with PodScript's configuration and targeting logic, automatically enforcing coloring and container names for significantly better readability.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Introduce a `logs` mode to fetch and tail logs for a given recipe's pod.
  * Support common logging flags: `--tail`, `--since`, `--until`, `--timestamps`.
  * Integrate with the existing `simulate` mode to preview the `podman pod logs` command.
  * Always pass `--color` and `--names` to Podman natively to ensure readable, distinguishable log output per container.
* **Non-Goals:**
  * Aggregating logs across multiple recipes or recipe groups simultaneously (restricted to one recipe per `logs` command to keep it simple and avoid interleaved pod logs).
  * Formatting or parsing logs within Lua (Podman handles the output streams directly).
  * Supporting remote log aggregation (e.g., syslog, journald) directly through PodScript logic.

### 1.4 Description
* **Syntax:** `pods logs [OPTIONS] [<action>] <recipe>[/container]`
* **Actions:**
  * `show`: Fetch and display the logs, then exit (Default when omitted and target is provided).
  * `follow`: Fetch and follow the logs (implicit `--follow`).
  * `help`: Display command-line help for logs mode (Default when no arguments are provided).
* **Target:**
  * `<recipe>`: Show logs for all containers in the recipe's pod.
  * `<recipe>/<container>`: Filter logs to a specific container defined in the recipe. The `<container>` part can be a numeric index (e.g., `1` for the first container), a relative name (e.g., `app` resolves to `<pod_name>-app`), or an exact absolute name.
* **Options:**
  * `--tail <n>`: Output the specified number of lines at the end of the logs.
  * `--since <timestamp>`: Show logs since timestamp.
  * `--until <timestamp>`: Show logs until timestamp.
  * `--timestamps`: Show timestamps in the log output.
* **Execution:**
  * The command resolves the specified recipe to extract the `pod.name`.
  * If a container is specified, it resolves the container name and translates it into the Podman command: `podman pod logs -n --color -c <resolved_container> [user_options] <pod_name>`. Otherwise, it omits the `-c` flag.
  * Uses blocking execution (e.g., `os.execute`) to stream `stdout` and `stderr` directly to the terminal.
* **Simulation:**
  * `pods simulate logs [OPTIONS] <action> <recipe>[/container]` prints the resolved Podman command instead of executing it.
* **Output & Exit Codes:**
  * Exits with the exit code returned by the underlying Podman process.

### 1.5 Alternatives
* Requiring users to manually execute `podman pod logs` for every task (rejected due to verbosity and lack of integration with PodScript's recipe context and container resolution).

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/mode_logs.lua` (New): Implements `mode_logs__execute(config, args)`.
* `src/pods/main.lua`: Register the `logs` mode in the router.
* `USAGE.md`: Document the new `logs` mode in the Modes Overview.

### 2.2 Schema & Syntax Changes
* No changes to `config.lua` or recipe schemas; this is purely a CLI command addition that relies on the existing recipe schema.

### 2.3 Implementation Details
* **Handler (`mode_logs__handle`)**:
  * Routes based on `context.action` (`show`, `follow`, or `help`).
  * If the parsed action is not `show`, `follow`, or `help`, it should be treated as the target, and the action should implicitly default to `show`.
  * If no arguments are provided, or `help` is explicitly called, invokes `mode_logs__help(context)`.
* **Target Resolution**:
  * Parses `context.targets[1]`. If it contains a `/`, splits it into `<recipe>` and `<container>`.
  * Loads the recipe via `recipe__load` and validates it via `recipe__validate`.
  * If a container is specified, resolves it using logic analogous to `mode_command.lua`:
    * If numeric, fetches from `recipe.containers[index]`.
    * If relative (starts with `*`), prepends `<pod_name>-`.
    * Ensures the absolute container name is retrieved.
* **Command Construction**:
  * Initializes an array `commands = { "podman", "pod", "logs", "-n", "--color" }`.
  * If action is `follow`, appends `-f`.
  * Extracts flags from `context.flags`:
    * `--since` -> `--since "<val>"` (ensure value is safely shell-escaped)
    * `--until` -> `--until "<val>"` (ensure value is safely shell-escaped)
    * `--tail` -> `--tail <val>`
    * `--timestamps` -> `--timestamps`
  * Appends `-c <resolved_container>` if applicable.
  * Appends `recipe.pod.name`.
* **Execution**:
  * Constructs the final string with `table.concat(commands, " ")`. Must safely quote/escape user-provided strings (like timestamps) to prevent shell injection.
  * If `context.flags.simulate` is true, prints the command using `log.print`.
  * If executing for real, the best approach is to use standard `os.execute` directly rather than `system.exec(..., direct=true)`, because PodScript's `system.exec` suppresses `stderr` in direct mode, but `stderr` is crucial for Podman log streams.
* Strict Lua 5.5 rules (`global<const> *`) and PodScript style guidelines must be followed.

### 2.4 Testing Strategy
* **Test Suites:**
  * `tests/pods/suite_019_mode_logs.lua`: Verify the command builder accurately maps PodScript flags to `podman pod logs` flags.
  * **Mocking:** `os.execute` MUST be mocked or stubbed during unit tests to ensure the test suite does not hang indefinitely when testing `follow` commands.
  * Validate container name resolution logic (e.g., `mypod/1` -> `-c mypod-ctr1`, `mypod/app` -> `-c mypod-app`).
  * Verify edge case option parsing (e.g., `--since=1h`) and verify shell-escaping of timestamp values.
  * Validate simulation mode output format.
* **Edge Cases & Failure Modes:**
  * Missing or invalid recipe name: Exits with a clear error indicating the recipe could not be found.
  * Providing multiple recipe targets: Exits with an error (e.g., "logs command only supports a single recipe target").
  * Invalid container index or name in target: Exits with a clear error (e.g., "Container 'x' not found in recipe 'y'").
  * Recipe pod does not exist or is not running: Podman handles this naturally by printing its own error to `stderr` and returning a non-zero exit code, which PodScript propagates.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Implement comprehensive unit tests in `tests/pods/` (TDD phase).
- [ ] Implement core logic in `src/pods/mode_logs.lua` to pass the tests.
- [ ] Register `logs` mode in `src/pods/main.lua`.
- [ ] Update `USAGE.md` with new CLI syntax.
- [ ] Add entry to `CHANGELOG.md`.
- [ ] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [ ] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-09-26:** Initial concept specification created. Enforced `--color` and `--names` by default for improved UX over raw Podman defaults.
* **2026-09-28:** Updated proposal to include `--timestamps`, implicit `show` action, `--tail` support, explicit shell-escaping/test-mocking requirements, and renamed the `tail` action to `follow`.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
