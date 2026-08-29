<p align="center">
  <img src="images/banner.png" width="500">
</p>

<p align="center">
  <a href="https://github.com/yusufk/ZoomacIt/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/yusufk/ZoomacIt/ci.yml?style=flat&label=CI" alt="CI"></a>
  <a href="https://github.com/yusufk/ZoomacIt/releases/latest"><img src="https://img.shields.io/github/v/release/yusufk/ZoomacIt?style=flat" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/yusufk/ZoomacIt?style=flat" alt="License"></a>
  <a href="CONTRIBUTORS.md"><img src="https://img.shields.io/github/contributors/yusufk/ZoomacIt?style=flat" alt="Contributors"></a>
  <img src="https://img.shields.io/badge/Swift-6.0-orange?style=flat&logo=swift&logoColor=white" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/macOS-target%2015%2B%20%7C%20supported%2026%2B-blue?style=flat&logo=apple&logoColor=white" alt="macOS target 15+ | supported 26+">
</p>

<p align="center">English | <a href="README_ja.md">日本語</a></p>

---

> ### 🔱 This is an actively maintained fork
>
> The original [07JP27/ZoomacIt](https://github.com/07JP27/ZoomacIt) was **archived by its author on 4 August 2026** after Microsoft Sysinternals shipped an official [ZoomIt for macOS](https://learn.microsoft.com/en-us/sysinternals/downloads/zoomit) (["Sherlocked"](https://github.com/07JP27/ZoomacIt/issues/42)).
>
> This fork ([**yusufk/ZoomacIt**](https://github.com/yusufk/ZoomacIt)) continues development. Contributions and issues are welcome.
>
> Thanks to [**@07JP27**](https://github.com/07JP27) and all original contributors for the foundation. 🙏

ZoomacIt is a native macOS menu bar app inspired by [ZoomIt for Windows](https://learn.microsoft.com/en-us/sysinternals/downloads/zoomit).

https://github.com/user-attachments/assets/5f7563e4-584b-4bab-99c4-70f7d3265f54

## Why this fork?

Microsoft's [ZoomIt for Mac](https://github.com/microsoft/ZoomitForMac) (MIT) is a faithful port of the Windows version — but brings Windows UX conventions to macOS.

**ZoomacIt is mac-native by design:**

- **Pure AppKit** — Swift 6 + AppKit. Feels like a Mac app because it *is* one.
- **AI-powered Snip** — Gemini AI analysis of screen regions (explain, summarise, extract text).
- **No telemetry** — Zero network calls except the optional AI feature (your key, your data).
- **GPL-3.0** — Stronger community protection. Forks must stay open.
- **Lightweight** — No external dependencies. XcodeGen, not SPM.

> **Looking for Microsoft's version?** [Sysinternals ZoomIt for Mac](https://github.com/microsoft/ZoomitForMac) is available via `brew install --cask microsoft/sysinternalstap/zoomit`.

## Installation

### Homebrew

```bash
brew tap yusufk/tap
brew trust yusufk/tap
brew install --cask zoomacit
```

> `brew trust` is required on Homebrew 4.x+ before installing casks from a
> third-party tap. If you prefer not to trust the whole tap, run
> `brew trust --cask yusufk/tap/zoomacit` to trust only this cask.

### Manual

Download the `.dmg` from [Releases](https://github.com/yusufk/ZoomacIt/releases/latest), drag to Applications, then:

```bash
xattr -cr /Applications/ZoomacIt.app
```

## Features

| Feature | Status | Notes |
|---|---|---|
| Zoom (Still) | ✅ | |
| Zoom (Live) | ✅ | Real-time magnification |
| Draw | ✅ | Spotlight, pen cursor, configurable default shape |
| DemoType | ✅ | File/clipboard input, control keywords |
| Break Timer | ✅ | |
| Snip | ✅ | Region → clipboard (⌃6) / file (⌃⇧6) |
| AI Snip | ✅ | Gemini analysis via context menu |
| Record | ✅ | Full screen recording (⌃5) |

## Development

```bash
make build       # Debug build
make test        # Run tests
make run         # Build and launch
make release     # Release build (signed)
make dmg VERSION=1.0.0  # Create distributable DMG
```

See [PLAN.md](PLAN.md) for roadmap. Architecture docs in [`design/`](design/).

## License

[GNU General Public License v3.0](LICENSE)

## Contributors

<a href="https://github.com/yusufk/ZoomacIt/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=yusufk/ZoomacIt" alt="Contributors" />
</a>

Built on the work of [**@07JP27**](https://github.com/07JP27) and [original contributors](https://github.com/07JP27/ZoomacIt/graphs/contributors).
