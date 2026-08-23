# ZoomacIt Fork — Continuation Plan

**Date**: 2026-08-23
**Status**: Active

## Context

The original [07JP27/ZoomacIt](https://github.com/07JP27/ZoomacIt) was archived on 4 August 2026 after Microsoft Sysinternals released an official [ZoomIt for macOS](https://github.com/microsoft/ZoomitForMac) (MIT license). See [issue #42](https://github.com/07JP27/ZoomacIt/issues/42).

This fork (`yusufk/ZoomacIt`) continues development. GPL-3.0 license fully permits this.

## Rationale

- ZoomacIt is mac-native (AppKit) vs Microsoft's Windows-first port
- AI-powered Snip feature (Gemini integration)
- GPL-3.0 copyleft vs MIT
- No telemetry, no external dependencies

## Homebrew

```bash
brew tap yusufk/tap
brew install --cask zoomacit
```

Tap repo: https://github.com/yusufk/homebrew-tap

## Future

- [ ] Integrate DemoType v2 rewrite (feature/demo-type-v2 branch)
- [ ] Notarization via GitHub Actions secrets
- [ ] Documentation site
- [ ] Panorama capture
- [ ] Mac App Store distribution
