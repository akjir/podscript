# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Added Lua version 5.4+ check on startup to ensure compatibility.
- Added a system check for Linux OS, as only Linux is supported.
- Added a system check for Podman version 5.8.0+ on startup.

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
