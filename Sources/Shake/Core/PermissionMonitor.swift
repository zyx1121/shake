import AppKit
import ApplicationServices
import CoreGraphics

@Observable
@MainActor
final class PermissionMonitor {
    var accessibilityGranted = false
    var screenRecordingGranted = false

    func refresh() {
        accessibilityGranted = AXIsProcessTrusted()
        screenRecordingGranted = CGPreflightScreenCaptureAccess()
    }

    @discardableResult
    func requestAccessibility() -> Bool {
        let opts: NSDictionary = ["AXTrustedCheckOptionPrompt": true]
        accessibilityGranted = AXIsProcessTrustedWithOptions(opts)
        return accessibilityGranted
    }

    @discardableResult
    func requestScreenRecording() -> Bool {
        screenRecordingGranted = CGRequestScreenCaptureAccess()
        return screenRecordingGranted
    }

    func openAccessibilitySettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    func openScreenRecordingSettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
    }

    private func open(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
