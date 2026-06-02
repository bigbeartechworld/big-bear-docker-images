# Changelog

All notable changes to this Odysseus Docker image will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [2026.06.01] - 2026-06-01

### Added
- Initial release of the Odysseus Docker image built from upstream source
- CI builds upstream `main` into a multi-arch image (amd64/arm64)
- CalVer date tags plus `<date>-<short-sha>` immutable tags
- Weekly SHA-guarded rebuild (skips when upstream `main` is unchanged)
- Full-stack docker-compose (odysseus + chromadb + searxng + ntfy)
- Dev and prod compose variants
- Build and smoke-test scripts
- Environment template (.env.example)

### Notes
- Upstream Odysseus is MIT licensed and has no formal releases (continuous main).
- The image carries `org.opencontainers.image.revision` for upstream traceability.
