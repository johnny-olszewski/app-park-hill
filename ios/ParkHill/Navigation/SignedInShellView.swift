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
        .modifier(TabAlerts(tab: tab, inCover: false))
        .fullScreenCover(item: $tab.cover) { cover in
            CoverView(cover: cover, close: tab.closeCover)
                .modifier(TabAlerts(tab: tab, inCover: true))
        }
        .sheet(item: $tab.presented) { route in
            NavigationStack {
                ScreenHostView(model: route.screen)
            }
            .environment(\.screenActions, tab.actions)
        }
    }
}

/// A full-screen cover: its root in its own navigation stack, with a
/// client-drawn close button at the leading edge (guide 5.5).
private struct CoverView: View {
    @Bindable var cover: CoverCoordinator
    let close: () -> Void

    var body: some View {
        NavigationStack(path: $cover.path) {
            ScreenHostView(model: cover.root)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    SwiftUI.ToolbarItem(placement: .topBarLeading) {
                        Button(action: close) {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel(String(localized: "cover.close", defaultValue: "Close"))
                        .accessibilityIdentifier("cover.close")
                    }
                }
                .navigationDestination(for: Route.self) { route in
                    ScreenHostView(model: route.screen)
                }
        }
        .environment(\.screenActions, cover.actions)
        .tint(Color.phInk)
    }
}

/// The tab's `call` confirmation and its backend messages (guide 5.5: an
/// alert, with one button for a message), shown over the cover while one is
/// open and over the tab otherwise.
private struct TabAlerts: ViewModifier {
    @Bindable var tab: TabCoordinator
    let inCover: Bool

    private var here: Bool { (tab.cover != nil) == inCover }

    func body(content: Content) -> some View {
        content
            .alert(
                tab.pendingCall?.confirm.title ?? "",
                isPresented: Binding(get: { here && tab.pendingCall != nil }, set: { if !$0 { tab.cancelCall() } }),
                presenting: tab.pendingCall
            ) { pending in
                Button(pending.confirm.confirmLabel, role: pending.isDestructive ? .destructive : nil) {
                    tab.confirm(pending)
                }
                Button(pending.confirm.cancelLabel, role: .cancel) {
                    tab.cancelCall()
                }
            } message: { pending in
                Text(pending.confirm.message)
            }
            .alert(
                tab.message ?? "",
                isPresented: Binding(get: { here && tab.message != nil }, set: { if !$0 { tab.message = nil } })
            ) {}
    }
}
