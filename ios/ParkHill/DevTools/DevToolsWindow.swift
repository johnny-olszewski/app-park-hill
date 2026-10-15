import SwiftUI
import UIKit

/// The window the pill and menu live in, one level above the app's own
/// window, so they stay on top of the full-screen covers and sheets the app
/// presents. It takes touches only on the pill or while the menu is open;
/// everywhere else they fall through to the app.
final class DevToolsWindow: UIWindow {
    /// The pill's frame in window coordinates, reported by the overlay.
    var pillFrame: CGRect = .zero

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let isMenuOpen = rootViewController?.presentedViewController != nil
        guard isMenuOpen || pillFrame.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }
}

/// Reports the window a SwiftUI view lands in, so the dev tools window can
/// join the same scene. Invisible and takes no touches.
struct HostWindowReader: UIViewRepresentable {
    let onWindow: @MainActor (UIWindow) -> Void

    func makeUIView(context: Context) -> ReaderView {
        ReaderView(onWindow: onWindow)
    }

    func updateUIView(_ uiView: ReaderView, context: Context) {}

    final class ReaderView: UIView {
        private let onWindow: @MainActor (UIWindow) -> Void

        init(onWindow: @escaping @MainActor (UIWindow) -> Void) {
            self.onWindow = onWindow
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window {
                onWindow(window)
            }
        }
    }
}
