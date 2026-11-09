# Ace Link

[![Release](https://img.shields.io/github/v/release/nts-sixblack/AceLink?sort=semver)](https://github.com/nts-sixblack/AceLink/releases/latest)
[![Docker image](https://img.shields.io/docker/v/sixblack/acelink?sort=semver&label=sixblack%2Facelink)](https://hub.docker.com/r/sixblack/acelink)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Ace Link is a macOS menu bar app for playing Ace Streams and magnet links in the media player of your choice.
Paste an `acestream://` or `magnet:` URL into the Ace Link menu, or open such a link from a browser, and Ace Link
starts the Ace Stream engine in Docker and hands the stream to your player.

> This is a maintained fork of [blaise-io/acelink](https://github.com/blaise-io/acelink) by Blaise Kal.
> It adds OrbStack support, more robust stream handling, a non-root engine container and a
> fully automated, versioned release pipeline. Tiếng Việt: [xem bên dưới](#hướng-dẫn-nhanh-tiếng-việt).

<img src="acelink.png" width="350" alt="Ace Link menu" />

## Contents

- [Requirements](#requirements)
- [Install](#install)
- [Usage](#usage)
- [Docker image](#docker-image)
- [Build from source](#build-from-source)
- [Releasing](#releasing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing) · [Security](#security) · [License](#license)

## Requirements

- macOS 10.13 High Sierra or later (Apple silicon and Intel — the app is a universal binary)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) **or** [OrbStack](https://orbstack.dev)
- On Apple silicon: Rosetta enabled for Docker (the Ace Stream engine only exists for `linux/amd64`).
  In Docker Desktop: *Settings → General → Use Rosetta for x86_64/amd64 emulation*. OrbStack enables it by default.
- A media player: [VLC](https://www.videolan.org/vlc/), [IINA](https://iina.io), [mpv](https://mpv.io), QuickTime or a web browser.

## Install

1. Download the latest **`Ace.Link.<version>.dmg`** from
   [Releases](https://github.com/nts-sixblack/AceLink/releases/latest).
2. (Optional) Verify it: `shasum -a 256 -c Ace.Link.<version>.dmg.sha256`
3. Open the DMG and drag **Ace Link** into **Applications**.
4. Ace Link is ad-hoc signed but **not notarized** (Apple does not accept P2P apps), so Gatekeeper blocks the
   first launch. Either right-click the app → *Open* → *Open*, or run:

   ```sh
   xattr -dr com.apple.quarantine "/Applications/Ace Link.app"
   ```

5. Launch Ace Link — its icon appears in the menu bar.

To update, choose *Update to Ace Link x.y.z* in the menu when it appears (Ace Link checks GitHub releases on
launch), download the new DMG and replace the app.

## Usage

1. Start Docker Desktop or OrbStack (Ace Link will try to start it for you).
2. Copy an `acestream://<id>`, a 40-character content ID or a `magnet:` URI, click the menu bar icon and choose
   **Open stream from clipboard**. Clicking an `acestream://` or `magnet:` link in a browser works too.
3. The first run pulls the engine image `sixblack/acelink:<app version>` (about 300 MB); after that streams
   start in seconds.
4. Choose your player with **Change media player…**. Ace Link does not transcode, so pick a player with broad codec
   support (VLC, IINA, mpv).
5. Recently played streams are listed under **History**.

When the player quits, Ace Link stops the stream. Quitting Ace Link stops the engine container.

## Docker image

The Ace Stream engine runs in the image **[`sixblack/acelink`](https://hub.docker.com/r/sixblack/acelink)**,
built from this repository's [`Dockerfile`](Dockerfile) by GitHub Actions only:

| Tag       | Built from                    | Use                                  |
|-----------|-------------------------------|--------------------------------------|
| `x.y.z`   | release tag `x.y.z`           | pulled by Ace Link `x.y.z`           |
| `latest`  | latest release tag            | standalone use                       |
| `edge`    | `master` branch               | testing unreleased changes           |

Security properties of the image:

- The Ace Stream tarball is downloaded over HTTPS and verified against a pinned SHA-256 checksum.
- The engine runs as an unprivileged `acestream` user, not root.
- Images are built in CI with BuildKit [provenance attestations and an SBOM](https://docs.docker.com/build/metadata/attestations/),
  so you can audit what is inside: `docker buildx imagetools inspect sixblack/acelink:latest --format '{{json .SBOM}}'`.
- Ace Link publishes the engine API (`6878`) and its playlist proxy (`6888`) on `127.0.0.1` only, so they are not reachable from your network.

### Run the engine without the app

```sh
docker run --platform=linux/amd64 --rm -p 127.0.0.1:6878:6878 sixblack/acelink
```

Then open one of these in a player:

```
http://127.0.0.1:6878/ace/getstream?id=<acestream id>
http://127.0.0.1:6878/ace/getstream?infohash=<magnet infohash>
http://127.0.0.1:6878/webui/player/<acestream id>        # built-in web player
```

Replace `127.0.0.1:` with `0.0.0.0:` (or drop it) only if you want other devices on your network to use the engine.

Custom engine configuration:

```sh
docker run --platform=linux/amd64 --rm -p 127.0.0.1:6878:6878 \
  -v "$(pwd)/acestream.conf:/opt/acestream/acestream.conf:ro" sixblack/acelink
```

See [`acestream.conf`](acestream.conf) for the default.

## Build from source

Requirements: Xcode 15 or later, Docker (for the image).

```sh
git clone https://github.com/nts-sixblack/AceLink.git
cd AceLink
make dmg      # builds builds/Ace.Link.<VERSION>.dmg (universal, ad-hoc signed)
make docker   # builds sixblack/acelink:<VERSION> locally
```

Or open `Ace Link.xcodeproj` in Xcode and run the *Ace Link* target. A locally built app pulls
`sixblack/acelink:<VERSION>`; to test a local image, build it with `make docker` first so Docker does not need to
pull it.

Project layout:

```
Ace Link/            Swift sources (AppKit menu bar app)
  Menu/              menu sections (open stream, history, player, update…)
  Services/          Docker engine, Ace Stream engine, playlist proxy
Dockerfile           Ace Stream engine image
player.html          replacement web player served by the engine
acestream.conf       default engine configuration
scripts/build-dmg.sh build + package the DMG
.github/workflows/   CI: Docker image and DMG releases
```

## Releasing

Releases are fully automated and versioned by git tag (no `v` prefix — the app compares its version with the
latest release tag):

```sh
echo 2.3.0 > VERSION
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 2.3.0" "Ace Link/Info.plist"
# update CHANGELOG.md
git commit -am "Release 2.3.0"
git tag 2.3.0 && git push origin master 2.3.0
```

Pushing the tag runs:

- [`docker.yml`](.github/workflows/docker.yml) → pushes `sixblack/acelink:2.3.0` and `:latest` to Docker Hub.
- [`release.yml`](.github/workflows/release.yml) → builds `Ace.Link.2.3.0.dmg` + `.sha256` and publishes the GitHub release.

One-time repository setup (*Settings → Secrets and variables → Actions*):

- Secret **`DOCKERHUB_TOKEN`**: a Docker Hub [access token](https://app.docker.com/settings/personal-access-tokens)
  with *Read & Write* scope for the `sixblack` account. Never commit it or use your account password.
- Variable **`DOCKERHUB_USERNAME`** (optional): defaults to `sixblack`.

## Troubleshooting

- **"Ace Link can't be opened"** — see step 4 of [Install](#install).
- **Stream does not start** — check that Docker is running and that `docker run --platform=linux/amd64 --rm sixblack/acelink --version` works.
  On Apple silicon make sure Rosetta emulation is enabled.
- **Image not found** — every app version needs a matching `sixblack/acelink:<version>` tag. Development builds of
  unreleased versions need `make docker` first.
- **Logs** — open Console.app, search for `Process: Ace Link`, click *Start streaming*, then reproduce the problem.
  Engine logs: `docker logs acelink--ace-stream-server`.

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Please do not post Ace Stream IDs
or links to pirated content.

## Security

See [SECURITY.md](SECURITY.md) for how to report vulnerabilities.

## Disclaimer

Ace Link is a player launcher. It does not host, index or provide any content. You are responsible for complying
with the laws of your country and the rights of content owners.

## License

[MIT](LICENSE) — © 2018 Blaise Kal, © 2026 SixBlack and contributors.

---

## Hướng dẫn nhanh (Tiếng Việt)

**Cài đặt**

1. Cài [Docker Desktop](https://www.docker.com/products/docker-desktop/) hoặc [OrbStack](https://orbstack.dev).
   Máy Apple silicon cần bật Rosetta cho Docker (*Settings → General → Use Rosetta…*).
2. Tải file **`Ace.Link.<version>.dmg`** mới nhất tại [Releases](https://github.com/nts-sixblack/AceLink/releases/latest),
   mở DMG và kéo **Ace Link** vào **Applications**.
3. App chưa được Apple notarize, lần đầu mở hãy chuột phải → *Open*, hoặc chạy:
   `xattr -dr com.apple.quarantine "/Applications/Ace Link.app"`

**Sử dụng**

1. Copy link `acestream://…` hoặc `magnet:…`, bấm biểu tượng Ace Link trên thanh menu → **Open stream from clipboard**
   (hoặc bấm trực tiếp link đó trên trình duyệt).
2. Lần đầu app sẽ tải image `sixblack/acelink:<version>` từ Docker Hub, các lần sau phát gần như ngay lập tức.
3. Chọn trình phát bằng **Change media player…** (khuyên dùng VLC, IINA hoặc mpv).

**Chỉ chạy Ace Stream engine bằng Docker**

```sh
docker run --platform=linux/amd64 --rm -p 127.0.0.1:6878:6878 sixblack/acelink
# mở trong trình phát: http://127.0.0.1:6878/ace/getstream?id=<acestream id>
```

Image `sixblack/acelink` chỉ được build bởi GitHub Actions từ `Dockerfile` trong repo này: tải Ace Stream qua HTTPS
và kiểm tra SHA-256, chạy bằng user không phải root, kèm SBOM và provenance attestation.

**Phát hành phiên bản mới**: cập nhật `VERSION` + `Info.plist`, commit, rồi `git tag x.y.z && git push origin x.y.z`.
CI sẽ tự build DMG, tạo GitHub release và đẩy image `sixblack/acelink:x.y.z` lên Docker Hub
(cần secret `DOCKERHUB_TOKEN` trong repo).
