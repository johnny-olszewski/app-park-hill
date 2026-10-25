import SwiftUI

/// The signed-in destination: the backend's tabs in the system tab bar, each
/// with its own navigation stack (guide 5.5: brand color and type only).
struct SignedInShellView: View {
    @Bindable var shell: ShellCoordinator
    let signOut: () -> Void // TEMPORARY(EP-04): remove with IOS-015/AND-015

    var body: some View {
        switch shell.state {
        case .loading:
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.phSurface)
        case .error:
            LaunchErrorScreen {
                Task { await shell.retry() }
            }
        case .tabs:
            TabView(selection: $shell.selectedTabID) {
                ForEach(shell.tabs) { tab in
                    TabRoot(
                        tab: tab,
                        signOut: tab.id == "home" ? signOut : nil // TEMPORARY(EP-04): remove with IOS-015/AND-015
                    )
                    .tabItem {
                        Label {
                            Text(tab.title)
                        } icon: {
                            AssetProvider.tabIcon(tab.iconKey)
                        }
                    }
                    .tag(Optional(tab.id))
                }
            }
            .tint(Color.phInk)
        }
    }
}

/// One tab: its root screen in a navigation stack, titled with the tab's title.
private struct TabRoot: View {
    @Bindable var tab: TabCoordinator
    let signOut: (() -> Void)? // TEMPORARY(EP-04): remove with IOS-015/AND-015

    var body: some View {
        NavigationStack(path: $tab.path) {
            ScreenHostView(model: tab.root)
                .navigationTitle(tab.title)
                .toolbar {
                    if let signOut { // TEMPORARY(EP-04): remove with IOS-015/AND-015
                        SwiftUI.ToolbarItem(placement: .topBarTrailing) { // TEMPORARY(EP-04): remove with IOS-015/AND-015
                            Button(String(localized: "shell.sign_out", defaultValue: "Sign out"), role: .destructive, action: signOut) // TEMPORARY(EP-04): remove with IOS-015/AND-015
                                .accessibilityIdentifier("home.signOut") // TEMPORARY(EP-04): remove with IOS-015/AND-015
                        } // TEMPORARY(EP-04): remove with IOS-015/AND-015
                    } // TEMPORARY(EP-04): remove with IOS-015/AND-015
                }
                .navigationDestination(for: Route.self) { route in
                    ScreenHostView(model: route.screen)
                }
        }
        .environment(\.screenActions, tab.actions)
        .sheet(item: $tab.presented) { route in
            NavigationStack {
                ScreenHostView(model: route.screen)
            }
            .environment(\.screenActions, tab.actions)
        }
    }
}
