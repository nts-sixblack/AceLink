# Changelog

All notable changes to this project are documented here. Versions follow [Semantic Versioning](https://semver.org);
each version has a matching DMG on [GitHub Releases](https://github.com/nts-sixblack/AceLink/releases) and a
matching engine image `sixblack/acelink:<version>` on [Docker Hub](https://hub.docker.com/r/sixblack/acelink).

## [2.2.0] - 2026-11-09

First release of the [nts-sixblack/AceLink](https://github.com/nts-sixblack/AceLink) fork.

### Added
- OrbStack support: Ace Link starts OrbStack when installed, falling back to Docker Desktop.
- Universal (Apple silicon + Intel) ad-hoc signed DMG with SHA-256 checksum, built and published by CI on every version tag.
- Engine image published as `sixblack/acelink` with SBOM and provenance attestations.

### Changed
- Engine container runs as an unprivileged `acestream` user instead of root.
- Engine and playlist proxy ports are published on `127.0.0.1` only.
- Docker availability is checked in the background, so the menu opens instantly.
- Update check and download link point to this repository.

### Fixed
- Crashes on streams without a title and when the engine fails to start.
- AppKit updates from background threads in the update check.
- More reliable detection of the media player quitting.

## [2.1.0] and earlier

See the upstream project: https://github.com/blaise-io/acelink/releases
