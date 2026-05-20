import SwiftUI

struct OverlayView: View {
    let components: [AnyOverlayComponent]

    var body: some View {
        VStack(spacing: 0) {
            let visible = components.enumerated().filter { $0.element.height() > 0 }
            ForEach(Array(visible.enumerated()), id: \.offset) { pairIdx, pair in
                if pairIdx > 0 {
                    Divider().background(Color.white.opacity(0.06))
                }
                pair.element.view()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 3)
        )
        // Absorb clicks on empty panel chrome so AppKit doesn't beep.
        // Foreground buttons still receive their taps.
        .contentShape(Rectangle())
        .onTapGesture { }
    }
}
