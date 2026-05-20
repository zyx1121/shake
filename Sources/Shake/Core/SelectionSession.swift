import AppKit
import Foundation

/// The user's current "selection session" — the set of assets they've captured
/// so far. Designed to grow: later we'll attach a prompt and AI responses here.
@Observable
@MainActor
final class SelectionSession {
    private(set) var assets: [Asset] = []
    var onChange: () -> Void = {}

    func add(_ asset: Asset) {
        assets.append(asset)
        onChange()
    }

    func remove(_ asset: Asset) {
        assets.removeAll { $0.id == asset.id }
        onChange()
    }

    func clear() {
        assets.removeAll()
        onChange()
    }

    func copy(_ asset: Asset) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch asset.kind {
        case .text(let s):
            pb.setString(s, forType: .string)
        case .image(let img):
            pb.writeObjects([img])
        }
    }
}
