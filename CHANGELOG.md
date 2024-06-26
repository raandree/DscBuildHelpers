# Changelog for DscBuildHelpers

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added support for CIM based properties.

### Changed

- Migration of build pipeline to Sampler.

### Fixed

- Initialize-DscResourceMetaInfo:
  - Fixed TypeConstraint, 'MSFT_KeyValuePair' should be ignored.
  - Fixed non-working caching test.
  - Added PassThru pattern for easier debugging.
  - Considering CIM instances names DSC_* in addition to MSFT_*.
- Get-DscResourceFromModuleInFolder:
  - Redesigned the function. It did not work with PowerShell 7 and
    PSDesiredStateConfiguration 2.0.7.
- Changed the remaining lines in alignment to PR #14.
