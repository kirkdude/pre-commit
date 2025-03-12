# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- CODE_OF_CONDUCT.md with Contributor Covenant
- GitHub issue and PR templates
- CHANGELOG.md for tracking changes
- Detailed installation instructions in README.md

### Changed

- Improved error handling in all installation scripts
- Updated Windows installation script with better PowerShell practices
- Added version pinning to Python requirements
- Made Linux script more robust and interactive
- Made macOS script compatible with both Intel and Apple Silicon Macs
- Fixed duplicate check-json hook in pre-commit configuration
- Updated CloudFormation linting path for broader compatibility
- Improved script output with better status messages

### Fixed

- Typos and formatting in README.md
- Outdated hooks in pre-commit configuration
- Issues with Windows script not properly checking prerequisites
- Manual SSH key generation in Linux script without user confirmation
