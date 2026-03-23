# Stamp

Taking screenshots and tired of cramming the menu bar clock into frame or running `date` in a terminal?

Stamp is a tiny floating timestamp overlay for macOS. No menu bar, no Dock icon. Drag it anywhere on screen, take a screenshot.

Perfect for audits, demos, bug reports, and compliance screenshots. (If your threat model includes a motivated forger, you need more than a floating clock. Stamp is for everyone else.)

![Stamp screencap](screencap.gif)

## Features

- Date, time, and timezone on a single line
- Optional metadata line (name, email, audit title, etc.)
- Dark/light mode toggle
- Local time or UTC
- Always on top, visible across all spaces
- Remembers your settings across launches

## Getting Started

Grab the latest build from GitHub releases. Download, unzip, & launch.

> **Note:** Stamp is not signed or notarized (yet?). macOS Gatekeeper will block it on first launch. Run `xattr -cr /Applications/Stamp.app` if you trust this packaging (with path matching where you've put the app), or build from source for yourself as below.

## Usage

Bring up whatever you need to screenshot, drag the Stamp applet into a sensible place nearby, then `Cmd-Shift-4` click-and-outline whatever portion of the screen you need.

With the applet itself:
- **Right-click** to access the menu: set metadata, toggle dark/light mode, switch timezone, dim/brighten, highlight, quit
- **Drag** to reposition
- **Cmd-Q** to quit (when focused)

## Build

### Requirements

- macOS 13 (Ventura) or later
- Xcode 15 or later (to build from source)
- Swift 5.9 or later

### Create an app bundle

```bash
./Scripts/bundle.sh
```

This generates the app icon, compiles a release build, and creates `Stamp.app`. Double-click to launch, drag to `/Applications`, etc.

### Run locally

```bash
swift run
```

## License

[MIT](LICENSE)
