import SwiftUI

/// Type-erased overlay component. Each component contributes (a) a height
/// (which can be 0 to hide itself based on env state) and (b) a SwiftUI view.
///
/// New components: write a SwiftUI view that takes `env: OverlayEnvironment`,
/// wrap it in an `AnyOverlayComponent` factory, and append to the
/// `FollowOverlayController.components` array.
@MainActor
struct AnyOverlayComponent {
    let height: () -> CGFloat
    let view: () -> AnyView

    init<V: View>(
        height: @escaping @MainActor () -> CGFloat,
        @ViewBuilder view: @escaping @MainActor () -> V
    ) {
        self.height = height
        self.view = { AnyView(view()) }
    }
}
