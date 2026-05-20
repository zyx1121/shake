import AppKit
import SwiftUI

@main
struct ShakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // No regular windows — UI lives entirely in the menubar popover and
        // in the floating overlay panels created by ShakeCoordinator.
        Settings { EmptyView() }
    }
}
