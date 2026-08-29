# Installation

## System Requirements

- **macOS 15** (Sequoia) or later
- **Screen Recording** permission (prompted on first launch)
- Universal binary — runs natively on both Apple Silicon and Intel Macs

## Homebrew (recommended)

```bash
brew tap yusufk/tap
brew trust yusufk/tap
brew install --cask zoomacit
```

::: tip
`brew trust` is required on Homebrew 4.x+ before installing casks from a
third-party tap. To trust only this cask instead of the whole tap, run
`brew trust --cask yusufk/tap/zoomacit`.
:::

The cask removes the quarantine flag for you, so no extra steps are needed.

## Manual Download & Install

1. Download the latest `.dmg` from the [Releases page](https://github.com/yusufk/ZoomacIt/releases/latest)
2. Open the `.dmg` file and drag **ZoomacIt.app** to the **Applications** folder
3. Open ZoomacIt from Applications

## Removing the Quarantine Flag

If you installed manually and see the warning *"Apple could not verify 'ZoomacIt' is free of malware that may harm your Mac or compromise your privacy"*, run the following command in **Terminal** to remove the quarantine flag:

```bash
xattr -cr /Applications/ZoomacIt.app
```

::: warning
Please review the [source code](https://github.com/yusufk/ZoomacIt) and run at your own risk.
:::

## Granting Screen Recording Permission

On first launch, macOS will prompt you to grant **Screen Recording** permission. This is required for the Zoom feature to capture the screen.

1. Click **Open System Settings** when prompted
2. Toggle **ZoomacIt** on in **Privacy & Security → Screen Recording**
3. Restart ZoomacIt if needed

::: tip
Screen Recording is the **only permission** ZoomacIt requires. No Accessibility permission is needed.
:::

## Launching

ZoomacIt runs as a **menu bar app** — there is no Dock icon. After launching, you will see the ZoomacIt icon in your menu bar.

<img src="/images/app_bar.png" width="200" alt="ZoomacIt menu bar">

From here you can:
- Launch **Zoom**, **Draw**, or **Break Timer** from the menu
- Open **Settings** to customize hotkeys and preferences
- Or simply use the default hotkeys: **⌃1** (Zoom), **⌃2** (Draw), **⌃3** (Break Timer)
