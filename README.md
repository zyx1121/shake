```
███████╗██╗  ██╗ █████╗ ██╗  ██╗███████╗
██╔════╝██║  ██║██╔══██╗██║ ██╔╝██╔════╝
███████╗███████║███████║█████╔╝ █████╗
╚════██║██╔══██║██╔══██║██╔═██╗ ██╔══╝
███████║██║  ██║██║  ██║██║  ██╗███████╗
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
```

# shake

> Wiggle the cursor: the element under it lights up, ready for whatever SwiftUI component you plugged in.

`macos` · `swiftui` · `accessibility` · `screencapturekit`

[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-111111)](Package.swift) &nbsp;[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](#license)

```
shake (≥4 reversals, ≥200px, under 0.4s) → dim + spotlight → left-click captures → right-click pins

[DebugLog] shake #1 overlay=shown
[DebugLog] captured #1 text: "Export to PDF"
[DebugLog] overlay pinned=true
```

<sub>The menubar popover shows this same log live, plus Accessibility / Screen Recording permission status.</sub>

macOS already binds cursor shake to "find my pointer," which wastes a good gesture on locating a cursor you can already see. shake reclaims it: wiggle anywhere on screen and the UI element under the cursor lights up, ready for whatever SwiftUI component you plug in (click-to-capture ships as the reference). It's a local homage to Google's Magic Pointer (DeepMind + Chrome, shipping on Googlebook): same gesture, your own stack instead of Gemini.

## Install

```bash
git clone https://github.com/zyx1121/shake && cd shake
make run
```

> [!NOTE]
> Requires Xcode 26, Swift 6, macOS 14+. `make run` builds, bundles, and codesigns with whichever Apple Development cert your local keychain has (override `SIGN_ID` in the Makefile for your own). Hardened Runtime is on.
> Not an SPM library dependency: `Package.swift` declares one `executableTarget`, so this is a fork-and-run menubar app, not something you `import Shake` into another project.

## What it gives you

- **Detects the shake**: ≥4 direction reversals inside 0.4s, ≥200px total cursor travel
- **Dims and spotlights**: every screen dims, a cutout follows the AX element under the cursor
- **Captures on click**: left-click while the overlay is up grabs the element (text goes in as text, anything else as a ScreenCaptureKit screenshot)
- **Pins on right-click**: freezes the overlay so you can mouse onto the tray and clean up captures
- **Lives in the menubar**: `LSUIElement` app, status bar icon opens a debug popover with state, permissions, and the event log

## Extending: drop in your own component

The overlay panel is a list of `AnyOverlayComponent`s plugged into `FollowOverlayController`. Each component is a SwiftUI view that reads `OverlayEnvironment` (observable state plus the command closures the coordinator wires) and never reaches into the coordinator or into other components.

1. Write a SwiftUI view that takes `env: OverlayEnvironment`, plus a `component(env:)` factory:

   ```swift
   // Sources/Shake/Overlay/Components/AskAI.swift
   struct AskAI: View {
       let env: OverlayEnvironment
       static let height: CGFloat = 64
       static func component(env: OverlayEnvironment) -> AnyOverlayComponent {
           AnyOverlayComponent(height: { height }, view: { AskAI(env: env) })
       }
       var body: some View {
           // read env.currentElement / env.session.assets here
       }
   }
   ```

2. Add whatever state or commands you need next to the existing `removeAsset` / `copyAsset` closures on `OverlayEnvironment`.

3. Wire it in `ShakeCoordinator.init` and append the component to the array:

   ```swift
   self.overlay = FollowOverlayController(
       env: env,
       components: [
           ElementHeader.component(env: env),
           CaptureTray.component(env: env),
           AskAI.component(env: env),   // ← yours
       ]
   )
   ```

Heights stack automatically, the panel resizes, and dim/pin/click-interceptor logic stays untouched. Directions people might build: an AskAI prompt bar, a per-card translate button, "send to Notes/Raycast/Things," a fixed-verb compare/synthesize toolbar, or a pin-and-timestamp daily log.

## Permissions

Two TCC entries, both prompted on first launch; the popover surfaces both with badges and deep links into System Settings.

| Permission | What for |
|------------|----------|
| Accessibility | `CGEventTap` for the click interceptor, `AXUIElementCopyElementAtPosition` for reading the element under the cursor |
| Screen Recording | `SCScreenshotManager` for screenshotting non-text elements (only needed if your components use `Capturer`) |

Stable Team ID means granting once survives `make bundle` rebuilds.

## Code layout

```
Sources/Shake/
├── App/        Coordinator + AppDelegate + entry
├── Core/       Asset · OverlayInfo · SelectionSession · DebugLog · PermissionMonitor
├── Capture/    ShakeDetector · ClickInterceptor · AXProbe · Capturer
├── Overlay/    OverlayPanel · OverlayEnvironment · OverlayView · DimOverlayController · FollowOverlayController
│   └── Components/   ElementHeader · CaptureTray   ← drop your own here
└── Status/     DebugMonitorView
```

`App/` / `Core/` / `Capture/` / `Overlay/` (minus `Components/`) is the framework; `Components/` is where your code goes.

## Status

Hobby project. Single contributor, no roadmap, no API stability, but the surface that matters (`OverlayEnvironment` + `AnyOverlayComponent`) is small and unlikely to thrash.

## Contributing

Issues and PRs welcome: start with [CONTRIBUTING.md](https://github.com/zyx1121/.github/blob/main/CONTRIBUTING.md).

## License

[MIT](LICENSE) · shake it till you make it
