import Foundation

/// Snapshot of the UI element currently under the cursor, as reported by AX.
struct OverlayInfo {
    var app: String = ""
    var role: String = ""
    var roleDescription: String = ""
    var title: String = ""
    var value: String = ""
    var frame: CGRect?

    var hasContent: Bool {
        !app.isEmpty || !role.isEmpty || !title.isEmpty || !value.isEmpty
    }
}
