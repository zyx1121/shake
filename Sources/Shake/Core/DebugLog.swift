import Foundation

@Observable
@MainActor
final class DebugLog {
    enum Level: String {
        case info, warn, error
    }

    struct Entry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: Level
        let message: String
    }

    private(set) var entries: [Entry] = []
    private let maxEntries = 500

    func append(_ level: Level, _ message: String) {
        entries.append(Entry(timestamp: Date(), level: level, message: message))
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
        NSLog("[shake] \(level.rawValue) \(message)")
    }

    func info(_ message: String)  { append(.info,  message) }
    func warn(_ message: String)  { append(.warn,  message) }
    func error(_ message: String) { append(.error, message) }

    func clear() {
        entries.removeAll()
    }
}
