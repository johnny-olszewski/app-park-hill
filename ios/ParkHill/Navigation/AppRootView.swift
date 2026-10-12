import SwiftUI

/// Renders whatever the app coordinator says the root is.
struct AppRootView: View {
    let coordinator: AppCoordinator
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch coordinator.state {
            case .loading:
                ProgressView()
            case .screen(let screen):
                screen.view
                    .id(screen.key)
            case .error:
                LaunchErrorScreen {
                    Task { await coordinator.retry() }
                }
            }
        }
        .task { await coordinator.start() }
        .onChange(of: scenePhase) { _, phase in
            Task { await coordinator.scenePhaseChanged(to: phase) }
        }
    }
}
