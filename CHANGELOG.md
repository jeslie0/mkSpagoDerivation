# Changelog

## [0.2.0] - 2024-01-14

_This release brings breaking changes that makes the usage of `mkSpagoDerivation` more consistent._

### Changed

- **Breaking:** Require a `spago.lock` file for dependency fetching
- **Breaking:** Remove internal use of purs and spago
- Update all tests to use the current version of `mkSpagoDerivation`

### Added

- Add tests for remote packages and local packages
- Build projects from `spago.lock` files ([#1](https://https://github.com/jeslie0/mkSpagoDerivation/issues/1))

### Removed

- Delete functionality to build PureScript project with only a `spago.yaml` file

### Fixed

- Local packages are now handled properly

## [0.1.0] - 2023-10-10

_Initial release._

[0.2.0]: https://github.com/jeslie0/mkSpagoDerivation/releases/tag/v0.2.0
[0.1.0]: https://github.com/jeslie0/mkSpagoDerivation/releases/tag/v0.1.0
