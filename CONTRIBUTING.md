# Contributing to Ace Link

Thanks for helping! Bug reports, fixes and improvements are welcome.

## Ground rules

- Do **not** include Ace Stream IDs, magnet links or links to websites with pirated content in issues or PRs.
- Keep pull requests focused: one fix or feature per PR.
- Be kind — see the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

## Development setup

```sh
git clone https://github.com/nts-sixblack/AceLink.git
cd AceLink
make docker   # build the engine image sixblack/acelink:<VERSION> locally
open "Ace Link.xcodeproj"
```

Run the *Ace Link* target from Xcode. Logs show up in Xcode's console and in Console.app (`Process: Ace Link`).

- Swift sources live in `Ace Link/`. Formatting follows [`Ace Link/.swiftformat`](Ace%20Link/.swiftformat)
  (`swiftformat "Ace Link"`).
- Engine changes go in `Dockerfile`, `acestream.conf` and `player.html`. Test with
  `docker run --platform=linux/amd64 --rm -p 127.0.0.1:6878:6878 sixblack/acelink:<VERSION>`.
- `make dmg` builds the same DMG CI publishes.

## Pull requests

1. Fork and create a branch from `master`.
2. Make sure `make dmg` (and `make docker` for engine changes) succeeds.
3. Add an entry under an *Unreleased* heading in [CHANGELOG.md](CHANGELOG.md).
4. Open the PR and describe what you tested (macOS version, Apple silicon/Intel, Docker Desktop/OrbStack, player).

Releases are cut by maintainers by pushing a version tag — see *Releasing* in the [README](README.md#releasing).
