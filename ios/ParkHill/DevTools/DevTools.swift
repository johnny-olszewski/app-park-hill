import SwiftUI

/// Debug builds' dev tools (EP-06): tracks the current screen for the menu.
/// Release builds compile `NoDevTools` instead, so nothing here ships.
@MainActor
final class DevTools {
    let environment: AppEnvironment
    let tracker = CurrentScreenTracker()

    init(environment: AppEnvironment, services: AppServices) {
        self.environment = environment
    }

    var screenTracker: (any ScreenTracker)? { tracker }

    func attach<Content: View>(to content: Content) -> some View {
        content
    }
}
