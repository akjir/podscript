# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Added `string.escape_shell` for safe shell argument execution.
- Added shell escaping for dynamic command arguments and paths.
- Added strict global declarations using Lua 5.5 `global<const> *`.
- Added Lua 5.5 named varargs support to log wrappers and `log.format_args`.
- Added multi-source variadic support to `table.append` and `table.merge`.

### Changed

- Updated minimum Lua requirement from 5.4 to 5.5.
- Refactored debug flag into `log.debug_enabled` to avoid global collisions.
- Updated `build.lua` to localize modular functions in release builds.
- Optimized table allocations across the codebase using `table.create`.
- Improved `table.remove_duplicates` with defensive `nil` and empty-table validation.

### Fixed

- Fixed path corruption for hidden host volume directories in container creation.
- Fixed recipe validation scope by initializing missing commands under pod node.
- Fixed command index table to retain undocumented commands for numeric execution.

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

- Renamed the generic `commands` field to `options` to avoid confusion with container startup commands.

### Removed

- Removed an internal `test` option.

## [1.0.0] - 2024-09-22

### Added

- Added the `all` argument to address clustered pods.
- Added `create`, `recreate`, `remove`, and `update` functions.
- Added PodConfig support.
