import Foundation
import Observation

/// One tab's navigation (guide 5.1): its root screen, the screens pushed over
/// it and the one presented as a sheet. Kept while the tab is switched away
/// from, so each tab returns to where it was.
@MainActor
@Observable
final class TabCoordinator: Identifiable {
    let id: String
    private(set) var title: String
    private(set) var iconKey: String
    let root: ScreenModel
    /// Screens pushed over the root, oldest first.
    var path: [Route] = []
    /// The screen presented as a sheet, if any.
    var presented: Route?
    /// The full-screen cover showing over the tab, if any.
    var cover: CoverCoordinator?

    private let context: ScreenContext

    init(item: TabItem, context: ScreenContext) {
        id = item.id
        title = item.title
        iconKey = item.iconKey
        root = ScreenModel(envelope: item.screen, context: context)
        self.context = context
    }

    /// Takes a refreshed title, icon and root screen for the same tab.
    func update(from item: TabItem) {
        title = item.title
        iconKey = item.iconKey
        root.update(item.screen)
    }

    /// What this tab's screens call when something is tapped.
    var actions: ScreenActions {
        ScreenActions(perform: { [weak self] action in self?.perform(action) })
    }

    /// Performs a backend action: `navigate` with `push` fetches the target
    /// screen over a loading state on this tab's stack; with
    /// `full_screen_cover` it opens a cover whose root is fetched fresh. An
    /// unknown action, or a target this build does not register, does nothing
    /// and is logged.
    func perform(_ action: Action) {
        switch action {
        case .navigate(let navigate):
            guard let screen = context.target(of: navigate) else { return }
            switch navigate.presentation {
            case .push:
                path.append(Route(screen: screen))
                Task { await screen.load() }
            case .fullScreenCover:
                let cover = CoverCoordinator(key: navigate.screenKey, params: navigate.params.objectValue, context: context)
                self.cover = cover
                Task { await cover.root.load() }
            }
        case .unknown:
            _ = ScreenActions.isKnown(action)
        }
    }

    /// Closes the full-screen cover, dropping its stack and screens.
    func closeCover() {
        cover = nil
    }

    /// Pushes the screen for `envelope`. False, and logged by the registry,
    /// when this build cannot show it.
    @discardableResult
    func push(_ envelope: ScreenEnvelope) -> Bool {
        guard context.registry.resolve(envelope) != nil else { return false }
        path.append(Route(screen: ScreenModel(envelope: envelope, context: context)))
        return true
    }

    /// Presents the screen for `envelope` as a sheet. False when this build
    /// cannot show it.
    @discardableResult
    func present(_ envelope: ScreenEnvelope) -> Bool {
        guard context.registry.resolve(envelope) != nil else { return false }
        presented = Route(screen: ScreenModel(envelope: envelope, context: context))
        return true
    }

    func pop() {
        _ = path.popLast()
    }

    func dismiss() {
        presented = nil
    }
}

/// One shown screen in a tab's stack or sheet. Identity is per showing, so
/// the same screen key can appear twice.
struct Route: Identifiable, Hashable {
    let id = UUID()
    let screen: ScreenModel

    static func == (lhs: Route, rhs: Route) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension JSONValue {
    /// The members of an object; empty for any other value.
    var objectValue: [String: JSONValue] {
        if case .object(let members) = self { return members }
        return [:]
    }
}
