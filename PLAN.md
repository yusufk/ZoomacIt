# ZoomacIt Fork — Continuation Plan

**Date**: 2026-08-23
**Status**: v1.0.0 Released ✅

## Context

The original [07JP27/ZoomacIt](https://github.com/07JP27/ZoomacIt) was archived on 4 August 2026 after Microsoft Sysinternals released an official [ZoomIt for macOS](https://github.com/microsoft/ZoomitForMac) (MIT license). See [issue #42](https://github.com/07JP27/ZoomacIt/issues/42).

This fork (`yusufk/ZoomacIt`) continues development. GPL-3.0 license fully permits this.

## Installation (Live)

```bash
brew tap yusufk/tap
brew install --cask zoomacit
```

Tap repo: https://github.com/yusufk/homebrew-tap

## Completed ✅

- [x] Merge all features into main (release/all-features branch)
- [x] README rewrite (fork notice, positioning, Homebrew, credits Microsoft version)
- [x] v1.0.0 tagged and released (DMG on GitHub Releases)
- [x] Homebrew tap created and verified working
- [x] Cask formula with correct SHA256

## Notarisation

**Not required for Homebrew distribution.** The cask runs `xattr -cr` in postflight which strips quarantine. Users won't see Gatekeeper warnings. Notarisation would remove the need for `xattr` but is optional — requires an Apple Developer Program membership ($99/year) and code signing setup in CI.

## Documentation Site

Plan: GitHub Pages from the `docs/` directory (already has VitePress setup).

Steps:
1. Update `docs/.vitepress/config.js` — change base URL and branding
2. Enable GitHub Pages in repo settings (source: GitHub Actions)
3. The existing `docs.yml` workflow already deploys on release — just needs the Pages source configured
4. URL will be: https://yusufk.github.io/ZoomacIt/

## Roadmap

### Short-term
- [ ] Enable GitHub Pages for documentation site
- [ ] Integrate DemoType v2 rewrite (feature/demo-type-v2 — needs manual merge, v2 lacks AI/Snip properties in Settings.swift)

### Medium-term
- [ ] Notarisation (optional — Apple Developer ID + GH Actions secrets)
- [ ] Panorama capture feature
- [ ] Webcam PiP overlay

### Long-term
- [ ] Mac App Store distribution (sandboxed variant)
- [ ] Custom domain for docs (e.g., zoomacit.yusuf.kaka.co.za)
