# shake

Swift 6 macOS menu bar app: a cursor shake spotlights the element under the cursor, and SwiftUI components act on it. Read [README.md](README.md) first.

## Rules

- A component reads `OverlayEnvironment` only. It never reaches into the coordinator or into another component.
- Keep the framework (`App/`, `Core/`, `Capture/`, `Overlay/`) separate from `Overlay/Components/`.
- Text capture comes before a screenshot. Ask for Screen Recording only when a component needs `Capturer`.
- Repository documents and code comments are English.

## Verify

```sh
make bundle
make run
```

The build needs Xcode 26 on macOS, so it is an exception to the sandbox rule. Shake the cursor over a window and watch the debug popover for `overlay=shown`, then left-click to capture and right-click to pin.
