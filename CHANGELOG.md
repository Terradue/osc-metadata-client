# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project uses SemVer-style release tags.

## [Unreleased]

### Changed

- Reorganized the project layout to match the EOAP CWL release workflow project
  structure contract.
- Regenerated CWL workflow documentation.
- Updated the `ogc-api-processes-client` dependency.

### Fixed

- Fixed URI string formatting in CWL workflows by using `$(self.value)`.
- Fixed `osc-metadata-client` CLI construction in the
  `publish_experiment_products` workflow.

## [0.3.0] - 2026-05-20

### Fixed

- Fixed the release by replacing a direct dependency with a publishable package
  dependency.

## [0.2.0] - 2026-05-20

### Changed

- Advanced the development version after the beta release.

### Fixed

- Removed a blocking test that was no longer useful for the release flow.

## [0.1.0-beta] - 2026-05-20

### Added

- Added initial CWL workflow definitions for publishing workflows and experiment
  products.
- Added a CWL git repository command-line tool.
- Added Docker image support.
- Added generated workflow documentation and diagrams.

### Changed

- Renamed the Python package module from `osc_client` to
  `osc_metadata_client`.
- Refined the `publish_workflow` CWL workflow to support Git iteration.
- Refined CWL workflows and regenerated their documentation.
- Updated project dependencies and related code references.
- Updated GitHub Actions dependencies for `actions/setup-python` and
  `actions/checkout`.

### Fixed

- Fixed workflow titles.
- Fixed broken references.
- Fixed lint issues.

## [0.1.0] - 2026-03-31

### Added

- Added the initial `osc-metadata-client` project skeleton, package metadata,
  and CLI.
- Added workflow, experiment, and product metadata production.
- Added support for Open Science Catalog workflow, experiment, and product
  records.
- Added OSC extension support and `osc:project` metadata handling.
- Added OGC API - Processes integration, including process, job, and job
  result links.
- Added support for authorization tokens when accessing generic OGC API -
  Processes endpoints.
- Added STAC Collection output handling for products.
- Added schema-driven extra properties and generated data models.
- Added sequence diagrams and relocated flow diagrams.
- Added tests, GitHub Actions, README documentation, and CLI documentation.

### Changed

- Refined workflow and extension metadata.
- Refined metadata output to satisfy STAC Node Validator
  `v2.0.0-beta.18` expectations.
- Updated parent `catalog.json` records when missing.
- Preserved output links by dumping workflow outputs to YAML instead of
  decomposing them across STAC Collection elements.
- Updated ignore rules.

### Fixed

- Fixed experiment production and product follow-up action handling.
- Fixed enum serialization to use enum values instead of strings.
- Fixed `ProductProperties.osc_experiment` as a URL.
- Fixed absolute URL derivation to avoid guessing from local references.
- Preserved original `rel` links.
- Fixed missing links, missing plugin configuration, broken tests, and lint
  issues.

[Unreleased]: https://github.com/Terradue/osc-metadata-client/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/Terradue/osc-metadata-client/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/Terradue/osc-metadata-client/compare/v0.1.0-beta...v0.2.0
[0.1.0-beta]: https://github.com/Terradue/osc-metadata-client/compare/v0.1.0...v0.1.0-beta
[0.1.0]: https://github.com/Terradue/osc-metadata-client/releases/tag/v0.1.0
