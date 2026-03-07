# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed

- Corrected an issue that could cause a file to be executed twice.
- Added validation for the `--config` argument to handle invalid names.

### Changed

- Improved internal code quality by fixing typos and renaming variables.

## [1.1.1] - 2025-11-04

### Fixed

- Update now respects the container registry.

## [1.1.0] - 2025-05-29

### Added

- Added an option to define a different registry per container.
- Added support for PodConfigs and PodScript configs.
- Added the ability to publish pods.
- Added the ability to define commands to execute inside a container.

### Changed

- Renamed 'commands' to 'options' for clarity.

### Removed

- Removed the internal 'test' option.

## [1.0.0] - 2024-09-22

### Added

- Added the 'all' argument to address clustered pods.
- Added 'create', 'recreate', 'remove', and 'update' functions.
- Added PodConfig support.
