import Foundation
import Observation
import OSLog

/// A screen presented as a full-screen cover (`full_screen_cover`): its own
/// root, fetched fresh each time the cover opens, and its own stack. Closing
/// the cover drops it, so the next opening starts over.
@MainActor
@Observable
final class CoverCoordinator: Identifiable {
    let id = UUID()
    let root: ScreenModel
    /// Screens pushed over the cover's root, oldest first.
    var path: [Route] = []

    private let context: ScreenContext

    init(key: String, params: [String: JSONValue], context: ScreenContext) {
        root = ScreenModel(key: key, params: params, context: context)
        self.context = context
    }

    /// What the cover's screens call when something is tapped.
    var actions: ScreenActions {
        ScreenActions(perform: { [weak self] action in self?.perform(action) })
    }

    /// Pushes `navigate` targets onto the cover's own stack. A cover opened
    /// from inside a cover is not supported, and is logged.
    func perform(_ action: Action) {
        guard case .navigate(let navigate) = action else {
            _ = ScreenActions.isKnown(action)
            return
        }
        switch navigate.presentation {
        case .push:
            guard let screen = context.target(of: navigate) else { return }
            path.append(Route(screen: screen))
            Task { await screen.load() }
        case .fullScreenCover:
            Logger.navigation.error("Ignored full_screen_cover to \(navigate.screenKey, privacy: .public) inside a cover")
        }
    }
}

extension ScreenContext {
    /// A screen model still to fetch for a `navigate` target, or nil, logged,
    /// when this build does not register the target's key.
    func target(of navigate: NavigateAction) -> ScreenModel? {
        guard registry.isRegistered(navigate.screenKey) else {
            Logger.navigation.error("Dropped navigation to unregistered screen key \(navigate.screenKey, privacy: .public)")
            return nil
        }
        return ScreenModel(key: navigate.screenKey, params: navigate.params.objectValue, context: self)
    }
}
