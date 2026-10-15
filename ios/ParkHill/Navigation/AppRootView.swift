import SwiftUI

/// The app's root: the signed-in destination, with the signed-out entry
/// presented over it as a full-screen cover.
struct AppRootView: View {
    let coordinator: AppCoordinator
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        root
            .fullScreenCover(isPresented: .constant(coordinator.isEntryPresented)) {
                EntryView(coordinator: coordinator)
                    .onAppear { coordinator.entryDidAppear() }
                    .environment(\.sessionEndedNotice, coordinator.signOutReason == .sessionEnded)
                    .tint(Color.phInk)
            }
            .tint(Color.phInk)
            .task { await coordinator.start() }
            .onChange(of: scenePhase) { _, phase in
                Task { await coordinator.scenePhaseChanged(to: phase) }
            }
    }

    /// The signed-in destination (tabs from IOS-008), or a plain surface while
    /// launching or behind the entry cover.
    @ViewBuilder
    private var root: some View {
        if let user = coordinator.signedInUser {
            SignedInPlaceholderView(user: user) { // TEMPORARY(EP-02): remove with IOS-008
                Task { await coordinator.signOut() } // TEMPORARY(EP-02): remove with IOS-008
            } // TEMPORARY(EP-02): remove with IOS-008
        } else {
            ZStack {
                Color.phSurface.ignoresSafeArea()
                if coordinator.isLaunching {
                    ProgressView().controlSize(.large)
                }
            }
        }
    }
}

/// The entry cover's content: loading, the backend's entry screen, or the
/// launch error.
private struct EntryView: View {
    let coordinator: AppCoordinator

    var body: some View {
        switch coordinator.entry {
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
        }
    }
}
