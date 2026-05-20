import AppKit
import SwiftUI

struct DebugMonitorView: View {
    let coordinator: ShakeCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            stats
            permissions
            logSection
            footer
        }
        .padding(16)
        .frame(width: 480, height: 480)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "cursorarrow.motionlines")
                .font(.system(size: 14, weight: .semibold))
            Text("Shake")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Text(coordinator.isMonitoring ? "MONITORING" : "IDLE")
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill(coordinator.isMonitoring
                                   ? Color.green.opacity(0.25)
                                   : Color.gray.opacity(0.25))
                )
                .foregroundStyle(coordinator.isMonitoring ? .green : .secondary)
        }
    }

    private var stats: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
            GridRow {
                Text("Overlay").foregroundStyle(.secondary)
                Text(coordinator.env.overlayVisible ? "ON" : "OFF").monospaced()
            }
            GridRow {
                Text("Triggers").foregroundStyle(.secondary)
                Text("\(coordinator.triggerCount)").monospaced()
            }
            GridRow {
                Text("Last shake").foregroundStyle(.secondary)
                Text(coordinator.lastTriggerAt.map { Self.fmt.string(from: $0) } ?? "—")
                    .monospaced()
            }
            GridRow {
                Text("Captures").foregroundStyle(.secondary)
                Text("\(coordinator.session.assets.count)").monospaced()
            }
        }
        .font(.system(size: 12))
    }

    private var permissions: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            HStack {
                permissionBadge(
                    label: "Accessibility",
                    granted: coordinator.permissions.accessibilityGranted,
                    action: coordinator.permissions.openAccessibilitySettings
                )
                permissionBadge(
                    label: "Screen Recording",
                    granted: coordinator.permissions.screenRecordingGranted,
                    action: coordinator.permissions.openScreenRecordingSettings
                )
                Spacer()
                Button("Refresh") { coordinator.permissions.refresh() }
                    .controlSize(.small)
            }
        }
    }

    private func permissionBadge(label: String, granted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Circle()
                    .fill(granted ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(label).font(.caption)
            }
        }
        .buttonStyle(.plain)
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Log")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if !coordinator.log.entries.isEmpty {
                    Button("Clear") { coordinator.log.clear() }
                        .controlSize(.small)
                }
            }
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.08))
                if coordinator.log.entries.isEmpty {
                    Text("No events yet.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(8)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(coordinator.log.entries.reversed())) { entry in
                                LogRow(entry: entry)
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Quit Shake", role: .destructive) {
                NSApp.terminate(nil)
            }
            .controlSize(.small)
        }
    }

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
}

private struct LogRow: View {
    let entry: DebugLog.Entry

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(Self.fmt.string(from: entry.timestamp))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
            Text(entry.level.rawValue.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 32, alignment: .leading)
            Text(entry.message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var color: Color {
        switch entry.level {
        case .info:  return .secondary
        case .warn:  return .orange
        case .error: return .red
        }
    }

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
}
