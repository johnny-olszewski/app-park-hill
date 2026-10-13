import SwiftUI

/// Renders whatever the app coordinator says the root is.
struct AppRootView: View {
    let coordinator: AppCoordinator
    let environment: AppEnvironment
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch coordinator.state {
            case .loading:
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.phSurface)
            case .screen(let screen):
                screen.view
                    .id(screen.key)
            case .error:
                LaunchErrorScreen {
                    Task { await coordinator.retry() }
                }
            case .signedIn(let user):
                SignedInPlaceholderView(user: user) { // TEMPORARY(EP-02): remove with IOS-008
                    Task { await coordinator.signOut() } // TEMPORARY(EP-02): remove with IOS-008
                } // TEMPORARY(EP-02): remove with IOS-008
            }
        }
        .tint(Color.phInk)
        .environment(\.backendTargetLabel, environment.showsBackendLabel ? environment.targetLabel : nil)
        .environment(\.sessionEndedNotice, coordinator.signOutReason == .sessionEnded)
        .task { await coordinator.start() }
        .onChange(of: scenePhase) { _, phase in
            Task { await coordinator.scenePhaseChanged(to: phase) }
        }
    }
}
