# Security Policy

## Supported versions

Only the latest release of Ace Link and the matching `sixblack/acelink` image receive fixes.

## Reporting a vulnerability

Please **do not** open a public issue. Report privately through
[GitHub Security Advisories](https://github.com/nts-sixblack/AceLink/security/advisories/new).
Include steps to reproduce, affected version and impact. You should get a response within 7 days.

## Supply chain

- The DMG is built from a tagged commit by [GitHub Actions](.github/workflows/release.yml); each release ships a
  `.sha256` file to verify the download.
- The engine image `sixblack/acelink` is built only by [GitHub Actions](.github/workflows/docker.yml) from the
  [`Dockerfile`](Dockerfile), with SBOM and provenance attestations. The upstream Ace Stream tarball is pinned by
  SHA-256 checksum.
- The engine runs as a non-root user and its ports are bound to `127.0.0.1` by the app.
- Docker Hub credentials are stored only as the `DOCKERHUB_TOKEN` repository secret (a scoped access token).
