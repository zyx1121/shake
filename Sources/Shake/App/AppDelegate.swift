import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = ShakeCoordinator()

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator.start()
        installStatusItem()
        installPopover()
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "cursorarrow.motionlines",
                accessibilityDescription: "Shake"
            )
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        statusItem = item
    }

    private func installPopover() {
        let p = NSPopover()
        p.behavior = .transient
        p.contentSize = NSSize(width: 480, height: 480)
        p.contentViewController = NSHostingController(
            rootView: DebugMonitorView(coordinator: coordinator)
        )
        popover = p
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            coordinator.permissions.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
