# Changelog

All notable changes to this MinIO Docker image will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-10-22

### Added
- Initial release of MinIO Docker image built from source
- Multi-stage Docker build process using Golang 1.24+
- Custom entrypoint script for user/group management with su-exec
- Health check configuration for container monitoring
- Comprehensive documentation (README.md, QUICKREF.md)
- Build script with multi-architecture support (AMD64/ARM64)
- Comprehensive test suite with 12 automated tests
- Development, production, and standard docker-compose configurations
- Environment variable template (.env.example)
- Security hardening (non-root user execution)
- Automated volume backup examples

### Changed
- Following MinIO's new source-only distribution model (as of October 2024)
- Building from source using `go install github.com/minio/minio@latest`
- Using Alpine Linux as base image for minimal footprint

### Security
- Running MinIO process as non-root user (minio:1000)
- Default credentials warning: minioadmin:minioadmin (MUST be changed in production!)
- Security options in production docker-compose (no-new-privileges)

### Notes
- MinIO team discontinued pre-built Docker images starting with RELEASE.2025-10-15T17-29-55Z
- This image is built from the official MinIO source repository
- Supports both AMD64 and ARM64 architectures
- Compatible with all MinIO releases from the source repository
- Follows Docker and security best practices

### References
- [MinIO Source-Only Distribution](https://github.com/minio/minio#source-only-distribution)
- [GitHub Issue #21647 - Docker Release Discussion](https://github.com/minio/minio/issues/21647)
- [MinIO Latest Release](https://github.com/minio/minio/releases/latest)

[Unreleased]: https://github.com/bigbeartechworld/big-bear-docker-images/compare/minio-v1.0.0...HEAD
[1.0.0]: https://github.com/bigbeartechworld/big-bear-docker-images/releases/tag/minio-v1.0.0
