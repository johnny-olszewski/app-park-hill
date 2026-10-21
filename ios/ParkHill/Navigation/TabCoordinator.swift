import Observation
import OSLog

/// One tab's navigation (guide 5.1): its root screen, the screens pushed over
/// it and the one presented as a sheet. Kept while the tab is switched away
/// from, so each tab returns to where it was.
@MainActor
@Observable
final class TabCoordinator: Identifiable {
    let id: String
    private(set) var title: String
    private(set) var iconKey: String
    let root: ResolvedScreen
    /// Screens pushed over the root, oldest first.
    var path: [Route] = []
    /// The screen presented as a sheet, if any.
    var presented: Route?

    private let registry: ScreenRegistry

    init(item: TabItem, root: ResolvedScreen, registry: ScreenRegistry) {
        id = item.id
        title = item.title
        iconKey = item.iconKey
        self.root = root
        self.registry = registry
    }

    /// Takes a refreshed title and icon for the same tab and root screen.
    func update(from item: TabItem) {
        title = item.title
        iconKey = item.iconKey
    }

    /// Pushes the screen for `envelope`. False, and logged by the registry,
    /// when this build cannot show it.
    @discardableResult
    func push(_ envelope: ScreenEnvelope) -> Bool {
        guard let screen = registry.resolve(envelope) else { return false }
        path.append(Route(screen: screen))
        return true
    }

    /// Presents the screen for `envelope` as a sheet. False when this build
    /// cannot show it.
    @discardableResult
    func present(_ envelope: ScreenEnvelope) -> Bool {
        guard let screen = registry.resolve(envelope) else { return false }
        presented = Route(screen: screen)
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
    let screen: ResolvedScreen

    static func == (lhs: Route, rhs: Route) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
