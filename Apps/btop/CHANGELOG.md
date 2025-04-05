# Changelog for btop

All notable changes to the btop Docker image will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.9] - 2025-04-04

### Added

- Authentication support for both gotty and ttyd versions
- Environment variables for controlling authentication:
  - `GOTTY_AUTH_USER` / `TTYD_AUTH_USER`: Username for authentication (default: "bigbear")
  - `GOTTY_AUTH_PASS` / `TTYD_AUTH_PASS`: Password for authentication (default: "password")
  - `GOTTY_AUTH_ENABLED` / `TTYD_AUTH_ENABLED`: Enable/disable authentication (default: "true")
- Updated entrypoint scripts to handle authentication logic
- Support for running with or without authentication via environment variables

### Changed

- Improved Dockerfile structure to follow best practices
- Removed unnecessary CMD instructions from Dockerfiles
- Updated entrypoint scripts to provide default commands when none are specified
- Fixed ENV instruction format in Dockerfiles to use key=value syntax
- Updated Alpine and Debian base images to latest versions

### Security

- Added basic authentication to protect btop web interface
- Implemented proper credential handling in entrypoint scripts
- Used ARG instructions for sensitive data with ENV overrides

## [0.0.8]

### Added

- Initial release of btop Docker image
- Support for both gotty and ttyd web terminal interfaces
- Basic configuration for btop monitoring tool
- Docker Compose files for easy deployment
- CasaOS integration
