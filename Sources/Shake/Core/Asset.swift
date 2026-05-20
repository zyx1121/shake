import AppKit
import Foundation

enum AssetKind {
    case text(String)
    case image(NSImage)
}

struct Asset: Identifiable {
    let id = UUID()
    let kind: AssetKind
    let source: String
    let capturedAt: Date

    var typeLabel: String {
        switch kind {
        case .text:  return "text"
        case .image: return "image"
        }
    }

    var summary: String {
        switch kind {
        case .text(let s):
            let oneLine = s.replacingOccurrences(of: "\n", with: " ")
            return String(oneLine.prefix(80))
        case .image(let img):
            return "image \(Int(img.size.width))×\(Int(img.size.height))"
        }
    }
}
