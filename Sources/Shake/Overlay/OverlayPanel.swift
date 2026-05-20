import AppKit

/// Shared base for any panel we put on screen. Always invisible to the
/// system-wide accessibility tree so AXProbe never picks up our own UI as
/// the element under the cursor.
final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func accessibilityRole() -> NSAccessibility.Role? { nil }
    override func accessibilityChildren() -> [Any]? { [] }
    override func isAccessibilityElement() -> Bool { false }
}
