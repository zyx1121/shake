import AppKit
import SwiftUI

struct CaptureTray: View {
    let env: OverlayEnvironment

    static let height: CGFloat = 92

    static func component(env: OverlayEnvironment) -> AnyOverlayComponent {
        AnyOverlayComponent(
            height: { env.session.assets.isEmpty ? 0 : height },
            view: { CaptureTray(env: env) }
        )
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(env.session.assets.reversed()), id: \.id) { asset in
                    CaptureCard(asset: asset) {
                        env.removeAsset(asset)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CaptureCard: View {
    let asset: Asset
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                )

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white, .black.opacity(0.75))
                    .padding(3)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: 4, y: -4)
        }
        .frame(width: 64, height: 64)
    }

    @ViewBuilder
    private var content: some View {
        switch asset.kind {
        case .image(let img):
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 64, height: 64)
                .clipped()
        case .text(let s):
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [Color(white: 0.22), Color(white: 0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                VStack(alignment: .leading, spacing: 3) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(s.prefix(48))
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }
                .padding(7)
            }
        }
    }
}
