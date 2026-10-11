<div align="center">

<h1>shake</h1>

<p><strong>Wiggle the cursor, and the UI element under it lights up for your SwiftUI component.</strong></p>

[![macOS](https://img.shields.io/badge/macOS-14%2B-000000?style=flat-square&logo=apple)](Package.swift)
[![License](https://img.shields.io/github/license/zyx1121/shake?style=flat-square)](LICENSE)

**English** | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md)

</div>

```
shake (≥4 reversals, ≥200px, under 0.4s) → dim + spotlight → left-click captures → right-click pins

[DebugLog] shake #1 overlay=shown
[DebugLog] captured #1 text: "Export to PDF"
[DebugLog] overlay pinned=true
```

macOS uses a cursor shake only to make the pointer bigger. shake gives the gesture a job: wiggle anywhere, and the element under the cursor lights up for the SwiftUI components that you plug in. Click-to-capture ships as the reference component. It is a local take on Google's Magic Pointer, on your own stack.

## Features

- **Detects a shake**: 4 or more direction changes within 0.4 seconds, with 200 px or more of cursor travel.
- **Dims and spotlights**: every screen dims, and a cutout follows the element under the cursor.
- **Captures on click**: a left click grabs the element, as text when it has text and as a ScreenCaptureKit screenshot otherwise.
- **Pins on right click**: the overlay stays, so you can move to the tray and clean up captures.
- **Lives in the menu bar**: the status icon opens a debug popover with the state, the permissions and the event log.

## Quick start

```sh
git clone https://github.com/zyx1121/shake && cd shake
make run
```

`make run` builds, bundles and signs the app with the Apple Development certificate in your keychain. Set `SIGN_ID` in the Makefile to use your own. Grant Accessibility and Screen Recording when macOS asks, then shake the cursor over any window.

The build needs Xcode 26, Swift 6 and macOS 14 or later.

## Usage

To add your own component:

1. Write a SwiftUI view that takes `env: OverlayEnvironment`, with a `component(env:)` factory:

   ```swift
   // Sources/Shake/Overlay/Components/AskAI.swift
   struct AskAI: View {
       let env: OverlayEnvironment
       static let height: CGFloat = 64
       static func component(env: OverlayEnvironment) -> AnyOverlayComponent {
           AnyOverlayComponent(height: { height }, view: { AskAI(env: env) })
       }
       var body: some View {
           // read env.currentElement and env.session.assets here
       }
   }
   ```

2. Add the state or commands that you need next to the `removeAsset` and `copyAsset` closures on `OverlayEnvironment`.
3. Add the component to the array in `ShakeCoordinator.init`:

   ```swift
   self.overlay = FollowOverlayController(
       env: env,
       components: [
           ElementHeader.component(env: env),
           CaptureTray.component(env: env),
           AskAI.component(env: env),
       ]
   )
   ```

The heights stack and the panel resizes by itself. A component never reaches into the coordinator or into another component.

## Configuration

| Permission | For |
|------------|-----|
| Accessibility | `CGEventTap` for the click interceptor, and `AXUIElementCopyElementAtPosition` for the element under the cursor |
| Screen Recording | `SCScreenshotManager` for screenshots of elements without text |

The popover shows both permissions with links to System Settings. A stable Team ID keeps the grants across rebuilds.

## How it works

```
Sources/Shake/
├── App/        coordinator, app delegate and entry point
├── Core/       Asset, OverlayInfo, SelectionSession, DebugLog, PermissionMonitor
├── Capture/    ShakeDetector, ClickInterceptor, AXProbe, Capturer
├── Overlay/    OverlayPanel, OverlayEnvironment, OverlayView, DimOverlayController, FollowOverlayController
│   └── Components/   ElementHeader, CaptureTray: your components go here
└── Status/     DebugMonitorView
```

Everything outside `Overlay/Components/` is the framework. `OverlayEnvironment` and `AnyOverlayComponent` are the only surface that a component uses.

## Limits

- It is a fork-and-run app, not a Swift package that you import.
- A hobby project with one contributor and no API stability promise.

## For AI agents

Facts for coding agents and LLM tools. The rules for changing the code are in [AGENTS.md](AGENTS.md).

- **Summary**: Swift 6 macOS menu bar app. A cursor shake spotlights the element under the cursor, and pluggable SwiftUI components act on it.
- **Type**: app
- **Interfaces**: menu bar UI and the `AnyOverlayComponent` extension point. No CLI, MCP or HTTP.
- **Install**: `make run` from a clone
- **Run**: `make run`
- **Verify**: `make bundle` succeeds, then a shake shows the overlay and the debug log prints `shake #1 overlay=shown`
- **Config**: `SIGN_ID` in the Makefile, Accessibility and Screen Recording permissions
- **Secrets**: none
- **Limits**: needs Xcode 26 and an Apple Development certificate.

## Development

```sh
make bundle
make run
```

There is no CI. The build needs a Mac with Xcode 26.

## License

[MIT](LICENSE)
