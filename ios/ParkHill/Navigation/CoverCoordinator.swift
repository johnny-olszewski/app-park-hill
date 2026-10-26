import Foundation
import Observation
import OSLog

/// A screen presented as a full-screen cover (`full_screen_cover`): its own
/// root, fetched fresh each time the cover opens, and its own stack. Closing
/// the cover drops it, so the next opening starts over. Calls and lost access
/// go to the tab that opened it, which owns the confirmation and messages.
@MainActor
@Observable
final class CoverCoordinator: Identifiable {
    let id = UUID()
    let root: ScreenModel
    /// Screens pushed over the cover's root, oldest first.
    var path: [Route] = []

    private let context: ScreenContext
    private let performCall: @MainActor (CallAction, ScreenModel?) -> Void
    private let presentSheet: @MainActor (NavigateAction, ScreenActions.PeopleHandler?) -> Void
    private let submit: ScreenActions.SubmitHandler?
    private let lostAccess: @MainActor (ScreenModel, String) -> Void

    init(
        key: String,
        params: [String: JSONValue],
        context: ScreenContext,
        performCall: @escaping @MainActor (CallAction, ScreenModel?) -> Void = { _, _ in },
        presentSheet: @escaping @MainActor (NavigateAction, ScreenActions.PeopleHandler?) -> Void = { _, _ in },
        submit: ScreenActions.SubmitHandler? = nil,
        lostAccess: @escaping @MainActor (ScreenModel, String) -> Void = { _, _ in }
    ) {
        root = ScreenModel(key: key, params: params, context: context)
        self.context = context
        self.performCall = performCall
        self.presentSheet = presentSheet
        self.submit = submit
        self.lostAccess = lostAccess
        root.onLostAccess = lostAccess
    }

    /// What the cover's screens call when something is tapped.
    var actions: ScreenActions {
        ScreenActions(coordinator: { [weak self] action, source, onPeople in self?.perform(action, from: source, onPeople: onPeople) }, submit: submit)
    }

    /// Pushes `navigate` targets onto the cover's own stack and hands sheets
    /// and calls to the tab. A cover opened from inside a cover is not
    /// supported, and is logged.
    func perform(_ action: Action, from source: ScreenModel? = nil, onPeople: ScreenActions.PeopleHandler? = nil) {
        switch action {
        case .navigate(let navigate):
            switch navigate.presentation {
            case .push:
                guard let screen = context.target(of: navigate) else { return }
                screen.onLostAccess = lostAccess
                path.append(Route(screen: screen))
                Task { await screen.load() }
            case .sheet:
                presentSheet(navigate, onPeople)
            case .fullScreenCover:
                Logger.navigation.error("Ignored full_screen_cover to \(navigate.screenKey, privacy: .public) inside a cover")
            }
        case .call(let call):
            performCall(call, source)
        case .unknown:
            _ = ScreenActions.isKnown(action)
        }
    }

    /// Whether `screen` is the cover's root or pushed inside it.
    func contains(_ screen: ScreenModel) -> Bool {
        root === screen || path.contains { $0.screen === screen }
    }

    /// Removes `screen` and everything pushed over it, returning the screen
    /// now on top. Nil for the root, which only closing the cover removes.
    func close(_ screen: ScreenModel) -> ScreenModel? {
        guard let index = path.firstIndex(where: { $0.screen === screen }) else { return nil }
        path.removeSubrange(index...)
        return path.last?.screen ?? root
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
