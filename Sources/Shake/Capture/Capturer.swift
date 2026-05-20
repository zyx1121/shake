import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import ScreenCaptureKit

@MainActor
final class Capturer {
    func capture(info: OverlayInfo) async -> Asset? {
        if isTextRole(info.role), let text = preferredText(from: info), !text.isEmpty {
            return Asset(
                kind: .text(text),
                source: sourceLabel(info: info),
                capturedAt: Date()
            )
        }
        guard let frame = info.frame else { return nil }
        if let img = await screenshot(cgRect: frame) {
            return Asset(
                kind: .image(img),
                source: sourceLabel(info: info),
                capturedAt: Date()
            )
        }
        return nil
    }

    private func isTextRole(_ role: String) -> Bool {
        switch role {
        case "AXStaticText", "AXTextField", "AXTextArea", "AXText", "AXHeading":
            return true
        default:
            return false
        }
    }

    private func preferredText(from info: OverlayInfo) -> String? {
        if !info.value.isEmpty { return info.value }
        if !info.title.isEmpty { return info.title }
        return nil
    }

    private func sourceLabel(info: OverlayInfo) -> String {
        var parts: [String] = []
        if !info.app.isEmpty { parts.append(info.app) }
        if !info.role.isEmpty { parts.append(info.role) }
        return parts.joined(separator: " · ")
    }

    private func screenshot(cgRect: CGRect) async -> NSImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )
            guard let display = displayContaining(cgRect, in: content) else { return nil }
            let myBundle = Bundle.main.bundleIdentifier ?? "dev.zyx1121.shake"
            let excluded = content.windows.filter {
                $0.owningApplication?.bundleIdentifier == myBundle
            }
            let filter = SCContentFilter(display: display, excludingWindows: excluded)

            let displayBounds = CGDisplayBounds(display.displayID)
            let localRect = CGRect(
                x: cgRect.origin.x - displayBounds.origin.x,
                y: cgRect.origin.y - displayBounds.origin.y,
                width: cgRect.width,
                height: cgRect.height
            )
            let scale = NSScreen.screens
                .first(where: { $0.cgDisplayID == display.displayID })?
                .backingScaleFactor ?? 2.0

            let config = SCStreamConfiguration()
            config.sourceRect = localRect
            config.width = max(1, Int(cgRect.width * scale))
            config.height = max(1, Int(cgRect.height * scale))
            config.showsCursor = false

            let cg = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            return NSImage(cgImage: cg, size: NSSize(width: cgRect.width, height: cgRect.height))
        } catch {
            NSLog("[shake] screenshot error: \(error)")
            return nil
        }
    }

    private func displayContaining(_ rect: CGRect, in content: SCShareableContent) -> SCDisplay? {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        for d in content.displays {
            if CGDisplayBounds(d.displayID).contains(center) {
                return d
            }
        }
        return content.displays.first
    }
}

extension NSScreen {
    var cgDisplayID: CGDirectDisplayID {
        let desc = deviceDescription
        if let n = desc[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return CGDirectDisplayID(n.uint32Value)
        }
        return 0
    }
}
