```text
███████╗██╗  ██╗ █████╗ ██╗  ██╗███████╗
██╔════╝██║  ██║██╔══██╗██║ ██╔╝██╔════╝
███████╗███████║███████║█████╔╝ █████╗
╚════██║██╔══██║██╔══██║██╔═██╗ ██╔══╝
███████║██║  ██║██║  ██║██║  ██╗███████╗
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
```

# shake

A menubar macOS app that turns a cursor wiggle into a system-wide selection overlay. Local homage to Google's Magic Pointer — the DeepMind + Chrome feature shipping on Googlebook this fall — except this one runs entirely on your Mac with no cloud, no Gemini, no sign-in.

Shake the mouse anywhere on screen → the world dims, the element under your cursor stays lit, click to capture it as text or a screenshot, right-click to pin the tray and curate what you grabbed.

## Why

Google's Magic Pointer demos make it look obvious that cursor shake should mean *summon assistance for whatever I'm pointing at*. Apple already uses cursor shake for "find my pointer" on macOS — same gesture, much less ambition. Shake is a sketch of what the gesture *could* be on macOS Tahoe: a fast, dependency-free trigger for any future "do something with this UI element" pipeline. Today the pipeline is capture-only. Tomorrow it could be Ask-AI, Translate, Compare, Pin-to-Notes — whatever you wire into the overlay.

## What it does

- **Detect**: rapid back-and-forth cursor motion (≥4 direction reversals inside 0.4s, ≥200px total travel).
- **Highlight**: dims every screen with a spotlight cutout around the `AXUIElement` under the cursor.
- **Capture**: left-click while the overlay is on
  - `AXStaticText` / `AXTextField` / `AXTextArea` / `AXText` / `AXHeading` → grab the raw string
  - anything else → screenshot the element's bounds via `ScreenCaptureKit` (Shake's own windows excluded from the capture)
- **Pin**: right-click freezes the overlay so you can mouse onto the tray, remove captures (`×` on each card), and otherwise stop chasing the panel around.
- **Live in the menubar**: `LSUIElement`, no Dock icon. Click the status bar `↗` for a debug popover with state, permissions, and the in-memory event log.

## Build

```bash
git clone https://github.com/zyx1121/shake
cd shake
make run
```

Requirements: Xcode 26 / Swift 6 / macOS 14+. The Makefile signs the bundle with an Apple Development cert from your local keychain; override `SIGN_ID` in the Makefile if your cert hash differs. Hardened Runtime is on by default.

## Permissions

Two TCC entries, both prompted on first launch. The popover surfaces both states with badges and deep links into System Settings.

| Permission | What for |
|------------|----------|
| Accessibility | `CGEventTap` for the click interceptor, `AXUIElementCopyElementAtPosition` for reading the element under the cursor |
| Screen Recording | `SCScreenshotManager` for screenshotting non-text elements |

Because the bundle is signed with a stable Team ID, granting once survives subsequent `make bundle` rebuilds.

## Architecture

```
Sources/Shake/
├── App/        ShakeApp · AppDelegate · ShakeCoordinator
├── Core/       Asset · OverlayInfo · SelectionSession · DebugLog · PermissionMonitor
├── Capture/    ShakeDetector · ClickInterceptor · AXProbe · Capturer
├── Overlay/    OverlayPanel · OverlayEnvironment · OverlayView · DimOverlayController · FollowOverlayController
│   └── Components/   ElementHeader · CaptureTray
└── Status/     DebugMonitorView
```

The overlay is a list of `AnyOverlayComponent`s plugged into `FollowOverlayController`. Each component is a SwiftUI view that reads `OverlayEnvironment` (observable state + command callbacks) — no component knows about the coordinator, the store, or any other component. Adding a new feature is a matter of writing the component, declaring its height contribution, and appending it to the array in `ShakeCoordinator.init`:

```swift
self.overlay = FollowOverlayController(
    env: env,
    components: [
        ElementHeader.component(env: env),
        CaptureTray.component(env: env),
        // AskAI.component(env: env),       ← future
        // ActionStrip.component(env: env), ← future
    ]
)
```

Need a new command from a component? Add a closure to `OverlayEnvironment` (`var askAI: (String) -> Void = { _ in }`), wire it in `ShakeCoordinator.wire()`, and the new component just calls `env.askAI(...)`.

## Status

Hobby project. No roadmap, no API stability, no support. The Magic Pointer demo videos still look nicer.

## License

MIT. See [LICENSE](./LICENSE).
