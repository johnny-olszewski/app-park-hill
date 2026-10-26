import OSLog
import SwiftUI

/// What screens call when something tappable is tapped. Screens never
/// navigate: the tab coordinator supplies these through the environment and
/// performs the backend's action (guide 5.1).
struct ScreenActions {
    var perform: @MainActor (Action) -> Void = { _ in }
    /// The coordinator's handler, given the screen each action came from.
    private var performFrom: (@MainActor (Action, ScreenModel?) -> Void)?

    init(perform: @escaping @MainActor (Action) -> Void = { _ in }) {
        self.perform = perform
    }

    /// A coordinator's actions: each is performed with the screen it came
    /// from, once `from(_:)` names it.
    init(coordinator: @escaping @MainActor (Action, ScreenModel?) -> Void) {
        perform = { coordinator($0, nil) }
        performFrom = coordinator
    }

    /// These actions for `screen`'s content, so a `call` can refresh or
    /// dismiss the screen it came from.
    func from(_ screen: ScreenModel) -> ScreenActions {
        guard let performFrom else { return self }
        var actions = self
        actions.perform = { performFrom($0, screen) }
        return actions
    }

    /// Whether this build knows the action's type. An unknown one makes its
    /// item not tappable (contract rule 3).
    func canPerform(_ action: Action) -> Bool {
        Self.isKnown(action)
    }

    /// True for action types this build performs; an unknown type is logged.
    static func isKnown(_ action: Action) -> Bool {
        switch action {
        case .navigate, .call:
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
