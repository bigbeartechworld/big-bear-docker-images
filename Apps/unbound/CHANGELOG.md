# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Unbound's release versioning](https://nlnetlabs.nl/projects/unbound/about/).

## [Unreleased]

## [1.24.2] - 2025-12-01

### Added
- Automated update workflow via GitHub Actions for checking and building new Unbound releases weekly
- Health checks to the Docker container for monitoring DNS resolver status
- TCP support for DNS queries in addition to UDP
- Comprehensive documentation in README.md with usage instructions, configuration details, and deployment examples
- Docker Compose files for development, production, and standard deployments

### Changed
- **Built Unbound 1.24.2 from source** instead of using Debian packages, enabling all latest security features
- Multi-stage Dockerfile build for smaller image size and security
- Enabled TCP Fast Open (TFO) for both client and server modes
- Enabled HTTP/2 support via libnghttp2 for DNS-over-HTTPS readiness
- Modernized unbound.conf with enhanced privacy and security options:
  - Enabled QNAME minimization for improved privacy
  - Added DNSSEC validation with aggressive NSEC support
  - Implemented security mitigations for DNSBomb, CAMP, and CacheFlush attacks
  - Enabled `harden-unverified-glue` (Unbound 1.22+ feature)
  - Enabled `wait-limit-cookie` for DoS protection
  - Enabled `iter-scrub-ns` and `max-global-quota` security options
  - Configured discard-timeout and other performance optimizations
- Updated root.hints file from InterNIC for current root server information
- Improved build.sh script with better versioning and error handling
- Updated config.json with current version and documentation links

### Removed
- Static root.key file (now generated dynamically at container startup)
- Dependency on Debian's outdated unbound package (version 1.17.1)

### Security
- Switched to non-root user execution in Docker container
- Enabled comprehensive DNS security features including DNSSEC validation and attack protections
- Built with Unbound 1.24.2 which includes the CVE-2025-11411 fix (first released in 1.24.1, domain hijacking protection)

