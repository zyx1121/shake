import SwiftUI

struct ElementHeader: View {
    let env: OverlayEnvironment

    static let height: CGFloat = 90

    static func component(env: OverlayEnvironment) -> AnyOverlayComponent {
        AnyOverlayComponent(
            height: { height },
            view: { ElementHeader(env: env) }
        )
    }

    var body: some View {
        let info = env.currentElement
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                if info.hasContent {
                    Text(info.app.isEmpty ? "—" : info.app)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(roleLine(info))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if !detail(info).isEmpty {
                        Text(detail(info))
                            .font(.system(size: 11))
                            .italic()
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                } else {
                    Text("Following cursor")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Click to capture · shake to hide")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 4)
            if env.overlayPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.orange)
                    .help("Pinned. Right-click anywhere to unpin.")
            }
            if !env.session.assets.isEmpty {
                Text("\(env.session.assets.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func roleLine(_ info: OverlayInfo) -> String {
        switch (info.role.isEmpty, info.roleDescription.isEmpty) {
        case (true, true):   return "no role"
        case (true, false):  return info.roleDescription
        case (false, true):  return info.role
        case (false, false): return "\(info.role) · \(info.roleDescription)"
        }
    }

    private func detail(_ info: OverlayInfo) -> String {
        if !info.title.isEmpty { return info.title }
        return info.value
    }
}
