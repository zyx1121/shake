```text
███████╗██╗  ██╗ █████╗ ██╗  ██╗███████╗
██╔════╝██║  ██║██╔══██╗██║ ██╔╝██╔════╝
███████╗███████║███████║█████╔╝ █████╗
╚════██║██╔══██║██╔══██║██╔═██╗ ██╔══╝
███████║██║  ██║██║  ██║██║  ██╗███████╗
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
```

# shake

A shake-trigger framework for macOS. Wiggle the cursor anywhere on screen — the world dims, the UI element under your cursor stays lit, and whatever component you plugged into the overlay gets called. macOS already uses cursor shake for "find my pointer"; this is what the gesture *could* be doing instead.

Local homage to Google's Magic Pointer (DeepMind + Chrome, shipping on Googlebook). Same gesture, your stack instead of Gemini.

## What you get out of the box

The framework ships one reference implementation — click-to-capture into a tray — so the overlay is useful on day one without writing anything:

- **Shake detection**: ≥4 direction reversals inside 0.4s, ≥200px total travel.
- **Spotlight dim**: every screen dims, a cutout follows the AX element under the cursor.
- **Click-to-capture**: left-click while the overlay is on grabs the element — text role goes in as text, anything else as a `ScreenCaptureKit` screenshot of the bounds.
- **Pin**: right-click freezes the overlay so you can mouse onto the tray and clean up captures.
- **Menubar-only**: `LSUIElement` app, status bar `↗` opens a debug popover with state, permissions, and the in-memory event log.

You can stop reading here if that's enough. The rest is for plugging your own behavior in.

## Extending: drop in your own component

The overlay panel is composed from a list of `AnyOverlayComponent`s plugged into `FollowOverlayController`. Each component is a SwiftUI view that reads `OverlayEnvironment` — observable state (current element, session assets, pinned flag) and command callbacks the coordinator wires. Components never reach into the coordinator or into each other.

**Three steps to add a new feature**:

1. Write a SwiftUI view that takes `let env: OverlayEnvironment`, plus a `component(env:)` factory:

   ```swift
   // Sources/Shake/Overlay/Components/AskAI.swift
   struct AskAI: View {
       let env: OverlayEnvironment
       static let height: CGFloat = 64

       static func component(env: OverlayEnvironment) -> AnyOverlayComponent {
           AnyOverlayComponent(height: { height }, view: { AskAI(env: env) })
       }

       var body: some View {
           // read env.currentElement / env.session.assets here,
           // call env.ask(prompt) when the user submits
       }
   }
   ```

2. Add any new state or commands you need to `OverlayEnvironment`:

   ```swift
   var ask: (String) -> Void = { _ in }
   var currentAnswer: String = ""
   ```

3. Wire them in `ShakeCoordinator.init` and append the component to the array:

   ```swift
   env.ask = { [weak self] prompt in self?.handleAsk(prompt) }

   self.overlay = FollowOverlayController(
       env: env,
       components: [
           ElementHeader.component(env: env),
           CaptureTray.component(env: env),
           AskAI.component(env: env),   // ← yours
       ]
   )
   ```

That's it. Heights stack automatically, the panel resizes, dim/pin/click-interceptor logic stays untouched.

Some directions people might build:

- **AskAI** — prompt bar + streaming response, sends the tray as `content` blocks to whichever LLM
- **Translate** — per-card translate button, target language from settings
- **Send to ___** — Notes, Raycast, Things, a shell script, an HTTP endpoint
- **Compare / Synthesize** — fixed-verb toolbar (mirrors Magic Pointer's demo)
- **Search** — quick web / Spotlight / Linear / Kagi lookup with the selection
- **Pin & timestamp** — drop captures into a daily log

## Build

```bash
git clone https://github.com/zyx1121/shake
cd shake
make run
```

Requires Xcode 26 / Swift 6 / macOS 14+. The Makefile signs the bundle with whichever Apple Development cert your local keychain has; override `SIGN_ID` for your own hash. Hardened Runtime is on.

## Permissions

Two TCC entries, both prompted on first launch. The popover surfaces both with badges and deep links into System Settings.

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

`App/` / `Core/` / `Capture/` / `Overlay/` (sans Components) is the framework. `Components/` is where your stuff goes.

## Status

Hobby project. Single contributor, no roadmap, no API stability — but the surface that matters (`OverlayEnvironment` + `AnyOverlayComponent`) is small and unlikely to thrash.

## License

MIT. See [LICENSE](./LICENSE).
