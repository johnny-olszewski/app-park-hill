import SwiftUI

// Compiled only in release configurations (Config/App.xcconfig, DEV_TOOLS_SOURCES).

typealias AppDevTools = NoDevTools

/// Release builds have no dev tools: no screen tracking and nothing drawn
/// over the app.
@MainActor
struct NoDevTools {
    init(environment: AppEnvironment, services: AppServices) {}

    var screenTracker: (any ScreenTracker)? { nil }

    func attach<Content: View>(to content: Content) -> Content {
        content
    }
}
