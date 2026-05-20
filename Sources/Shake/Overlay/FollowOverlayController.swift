import AppKit
import SwiftUI

@MainActor
final class FollowOverlayController {
    private let env: OverlayEnvironment
    private let components: [AnyOverlayComponent]

    private var window: NSPanel?
    private var hostingView: NSHostingView<OverlayView>?

    var onFrameChange: ((CGRect) -> Void)?

    private let panelWidth: CGFloat = 360
    private let dividerHeight: CGFloat = 1

    var isVisible: Bool { window?.isVisible == true }

    init(env: OverlayEnvironment, components: [AnyOverlayComponent]) {
        self.env = env
        self.components = components
    }

    func toggle() {
        if isVisible { hide() } else { show() }
    }

    func show() {
        ensureWindow()
        resizeWindow()
        updatePosition(cursor: NSEvent.mouseLocation)
        window?.orderFrontRegardless()
        emitFrame()
    }

    func hide() {
        window?.orderOut(nil)
        emitFrame()
    }

    /// Re-render and re-fit. Called whenever observable env changes that affect
    /// component heights.
    func refresh() {
        guard let host = hostingView else { return }
        host.rootView = OverlayView(components: components)
        resizeWindow()
    }

    func updatePosition(cursor: NSPoint) {
        guard let w = window, w.isVisible else { return }
        if env.overlayPinned { return }
        let off = NSPoint(x: 18, y: -w.frame.height - 6)
        w.setFrameOrigin(NSPoint(x: cursor.x + off.x, y: cursor.y + off.y))
        emitFrame()
    }

    var panelCGFrame: CGRect {
        guard let w = window, w.isVisible else { return .zero }
        guard let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero })
                ?? NSScreen.main
        else { return .zero }
        let cocoa = w.frame
        return CGRect(
            x: cocoa.origin.x,
            y: primary.frame.height - cocoa.maxY,
            width: cocoa.width,
            height: cocoa.height
        )
    }

    private func emitFrame() {
        onFrameChange?(panelCGFrame)
    }

    private func computedSize() -> NSSize {
        var h: CGFloat = 0
        var visibleCount = 0
        for c in components {
            let ch = c.height()
            if ch > 0 {
                if visibleCount > 0 { h += dividerHeight }
                h += ch
                visibleCount += 1
            }
        }
        return NSSize(width: panelWidth, height: max(h, 1))
    }

    private func resizeWindow() {
        guard let w = window else { return }
        // When pinned, anchor the top-left so the panel grows / shrinks
        // downward instead of jumping to wherever the cursor is now.
        let oldTopY = w.frame.maxY
        let oldX = w.frame.origin.x
        w.setContentSize(computedSize())
        if w.isVisible {
            if env.overlayPinned {
                let newOrigin = NSPoint(x: oldX, y: oldTopY - w.frame.height)
                w.setFrameOrigin(newOrigin)
                emitFrame()
            } else {
                updatePosition(cursor: NSEvent.mouseLocation)
            }
        }
    }

    private func ensureWindow() {
        if window != nil { return }
        let size = computedSize()
        let w = OverlayPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        w.ignoresMouseEvents = false
        w.isMovableByWindowBackground = false

        let host = NSHostingView(rootView: OverlayView(components: components))
        host.frame = NSRect(origin: .zero, size: size)
        w.contentView = host

        window = w
        hostingView = host
    }
}
