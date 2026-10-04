# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Added cross-check to `recipe list` showing unconfigured files via `--all`.

### Changed

- Changed default action for `recipe` mode from `help` to `list`.

### Fixed

- Fixed cryptic file open error when showing missing recipes in `recipe` mode.
- Fixed status column alignment for items exceeding default padding limit.

### Removed

- Removed `--orphans` flag alias from `recipe list` command.

## [1.5.0] - 2026-10-04

### Added

- Added `connect` mode for interactive shell access to running containers.
- Added `logs` mode to fetch and tail logs from pods and containers.
- Added explicit `exec` action to `command` mode to run container commands.
- Added `status` action to query and display runtime status of managed containers.
- Added `--all` and `--full` flags for the `status` command.
- Added `task` shell script to simplify the development and testing workflow.
- Added `.task-completion.bash` to enable terminal tab-completion for the `task` script.
- Added `init` mode to initialize default configuration and recipe files.

### Changed
- Refactored `system.exec` to use an options table for flexible command execution.

- Changed `config show` output to a structured, hierarchical diagnostic tree.
- Renamed `print` action to `show` in `config` and `recipe` modes.
- Changed default container `detach` option to `true`.
- Downgraded default pod path fallback log to debug.
- Updated `recipe` mode to default to `show` action for unknown parameters.

### Fixed

- Fixed missing interactive progress bar during container image updates.
- Fixed `pods command` to allow `list` as the first parameter.
- Fixed crash during command validation by passing missing recipe argument.
- Fixed missing nil-safety and early validation across all mode handlers and core functions.
- Fixed `recipe__load` global error in `status` by correcting module build order.
- Fixed a crash in `string.trim` when providing a `nil` value.
- Fixed column shifting in `status` action by using robust delimiters.
- Fixed `simulate` flag being bypassed during `recipe` and `config` edit modes.
- Fixed `simulate` mode being bypassed for default actions when config disables simulation.

## [1.4.0] - 2026-09-24

### Added

- Added shell escaping for dynamic command arguments and paths.
- Added strict global declarations using Lua 5.5 `global<const> *`.
- Added dynamic Git build numbers and metadata to version outputs.
- Added `list` action to `recipe` mode for displaying configured recipes.

### Changed

- Refactored `system.exec` to use an options table for flexible command execution.
- Updated minimum Lua requirement from 5.4 to 5.5.
- Refactored debug flag into `log.debug_enabled` to avoid global collisions.
- Updated `build.lua` to localize modular functions in release builds.
- Optimized table allocations across the codebase using `table.create`.
- Improved `table.remove_duplicates` with defensive `nil` and empty-table validation.
- Updated mode help banners to display extended SemVer version strings.
- Updated recipe resolution error to report missing recipes instead of targets.
- Updated `recipe` mode to display help when no action is specified.

### Fixed

- Fixed path corruption for hidden host volume directories in container creation.
- Fixed recipe validation scope by initializing missing commands under pod node.
- Fixed command index table to retain undocumented commands for numeric execution.
- Fixed missing CLI modes and debug option across help outputs.
- Fixed shell escaping on pod and container options preventing multi-word flags.

### Removed

- Removed `--simulate` flag in favor of dedicated `simulate` mode.

## [1.3.0] - 2026-04-24

### Added

- Added Lua version 5.4+ check on startup to ensure compatibility.
- Added a system check for Linux OS, as only Linux is supported.
- Added a system check for Podman version 5.8.0+ on startup.
- Added a check for elevated privileges (sudo) with a mandatory confirmation prompt.
- Added a new `config` mode with `edit`, `print`, and `help` actions.
- Added a new `recipe` mode with `edit`, `print`, and `help` actions.
- Added a new `command` mode with `list`, `execute`, and `help` actions.

## [1.2.0] - 2026-03-28

### Added

- Added a `--simulate` argument to override the config file option.
- Added support for user-defined recipe groups in the PodScript configuration.
- Added the ability to target recipe groups using the `@` prefix in the target argument.

### Changed
- Refactored `system.exec` to use an options table for flexible command execution.

- Renamed `dryrun` option to `simulate` for better clarity.
- Renamed `PodConfig` to `Recipe` for better clarity.
- Improved internal code quality by fixing typos and renaming variables for consistency.
- Distinct between absolute and relative container naming.

### Removed

- Removed the default `all` target argument.
- Removed the `cluster` and `single` parameters from the PodScript config file in favor of recipe groups.

### Fixed

- Fixed an issue that could cause a recipe file to be executed multiple times.
- Added validation for the `--config` argument to prevent errors from invalid names.

## [1.1.1] - 2025-11-04

### Fixed

- The `update` command now correctly respects the container registry.

## [1.1.0] - 2025-05-29

### Added

- Added the ability to specify a different registry for each container.
- Added a generic `options` field to pod and container configurations for custom flags.
- Added a `publish` option to pods for exposing ports.
- Added a `commands` field to containers for running commands on startup.

### Changed
- Refactored `system.exec` to use an options table for flexible command execution.

- Renamed the generic `commands` field to `options` to avoid confusion with container startup commands.

### Removed

- Removed an internal `test` option.

## [1.0.0] - 2024-09-22

### Added

- Added the `all` argument to address clustered pods.
- Added `create`, `recreate`, `remove`, and `update` functions.
- Added PodConfig support.
