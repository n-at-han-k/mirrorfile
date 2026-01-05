# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
