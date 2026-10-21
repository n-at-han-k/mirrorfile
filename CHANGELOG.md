# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-10-21

### Added

- `mirror init` now declares `mirrorfile` in an existing `Gemfile`: when the
  project root has a `Gemfile` that does not already depend on the gem,
  `Mirrorfile::Mirror#init` runs `bundle add mirrorfile` before creating the
  Mirrorfile. Projects without a `Gemfile` are unaffected, and an existing
  declaration is left alone. A failing `bundle add` raises `Mirrorfile::Error`.

### Changed

- `gem_kit` (`~> 0.2`) is now a runtime dependency of the gem, not just a
  development one.

## [0.1.0] - 2024-01-01

### Added

- Initial release
- `mirror init` command to initialize projects
- `mirror install` command to clone repositories
- `mirror update` command to pull latest changes
- `mirror list` command to show defined mirrors
- Mirrorfile DSL with `source` and `mirror` methods
- Rails/Zeitwerk integration for autoloading mirrored code
- Automatic `.gitignore` management
