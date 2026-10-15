import SwiftUI
import UIKit

/// Debug builds' dev tools (EP-06): the pill and menu over the app, the
/// current screen for the menu, and the tools it offers. Release builds
/// compile `NoDevTools` instead, so nothing here ships.
@MainActor
final class DevTools {
    let environment: AppEnvironment
    let tracker = CurrentScreenTracker()
    private(set) var registry = DevToolRegistry()
    private var window: DevToolsWindow?
    private weak var appWindow: UIWindow?

    init(environment: AppEnvironment, services: AppServices) {
        self.environment = environment
    }

    var screenTracker: (any ScreenTracker)? { tracker }

    /// The app's root, unchanged; once it is in a window, the dev tools window
    /// is added above it.
    func attach<Content: View>(to content: Content) -> some View {
        content.background(HostWindowReader { [weak self] window in self?.install(over: window) })
    }

    /// The menu may take key status from the app's window; give it back, so
    /// the app's text fields keep the keyboard.
    func menuDidClose() {
        appWindow?.makeKey()
    }

    private func install(over appWindow: UIWindow) {
        guard window == nil, let scene = appWindow.windowScene else { return }
        self.appWindow = appWindow
        let window = DevToolsWindow(windowScene: scene)
        window.windowLevel = appWindow.windowLevel + 1
        let host = UIHostingController(rootView: DevToolsOverlay(devTools: self) { [weak window] frame in
            window?.pillFrame = frame
        })
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false
        self.window = window
    }
}
