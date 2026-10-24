import OSLog
import SwiftUI

/// What screens call when something tappable is tapped. Screens never
/// navigate: the tab coordinator supplies these through the environment and
/// performs the backend's action (guide 5.1).
struct ScreenActions {
    var perform: @MainActor (Action) -> Void = { _ in }

    /// Whether this build knows the action's type. An unknown one makes its
    /// item not tappable (contract rule 3).
    func canPerform(_ action: Action) -> Bool {
        Self.isKnown(action)
    }

    /// True for action types this build performs; an unknown type is logged.
    static func isKnown(_ action: Action) -> Bool {
        switch action {
        case .navigate:
            return true
        case .unknown(let type):
            Logger.navigation.error("Ignored action of unknown type \(type ?? "none", privacy: .public)")
            return false
        }
    }
}

extension EnvironmentValues {
    @Entry var screenActions = ScreenActions()
}
