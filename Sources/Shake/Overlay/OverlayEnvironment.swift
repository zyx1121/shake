import AppKit
import Foundation

/// Shared state + commands that overlay components observe and call into.
///
/// Components never reach into the coordinator directly — they only read the
/// observable properties here and invoke the closures the coordinator wires.
/// To extend the overlay with new behavior (e.g. an "Ask AI" component),
/// add a property + a closure here and components can use them.
@Observable
@MainActor
final class OverlayEnvironment {
    var currentElement: OverlayInfo = OverlayInfo()
    var overlayVisible: Bool = false
    /// When true, the overlay stops following the cursor and freezes its
    /// highlight, so the user can move the cursor onto the panel to interact
    /// with assets (e.g. click an X to remove a capture).
    var overlayPinned: Bool = false

    let session: SelectionSession

    // Commands. Coordinator sets these at wire-up time.
    var removeAsset: (Asset) -> Void = { _ in }
    var copyAsset: (Asset) -> Void = { _ in }

    init(session: SelectionSession) {
        self.session = session
    }
}
