import Observation
import OSLog

/// The signed-in shell (EP-02): the backend's tabs, each with its own
/// `TabCoordinator`. Fetched with `get_tabs`, cached per locale, refreshed on
/// return to the foreground (guide 5.3).
@MainActor
@Observable
final class ShellCoordinator {
    enum State: Equatable {
        case loading
        case tabs
        case error
    }

    /// The tab bar's limit; the backend enforces it too (SUP-008).
    static let maximumTabs = 5

    private(set) var state: State = .loading
    private(set) var tabs: [TabCoordinator] = []
    /// The selected tab's id. A fresh shell selects the first tab.
    var selectedTabID: String?

    private let backend: any BackendService
    private let registry: ScreenRegistry
    private let cache: TabsCache
    private let locale: () -> String
    private let screens: ScreenContext

    init(
        backend: any BackendService,
        registry: ScreenRegistry,
        cache: TabsCache,
        screenCache: ScreenCache = .standard,
        locale: @escaping () -> String
    ) {
        self.backend = backend
        self.registry = registry
        self.cache = cache
        self.locale = locale
        screens = ScreenContext(backend: backend, registry: registry, cache: screenCache, locale: locale)
    }

    /// Fetches the tabs. Also the foreground refresh: a failure keeps the tabs
    /// showing; a refusal of the session signs out through the auth service.
    func load() async {
        let locale = locale()
        let response: TabsResponse
        do {
            response = try await backend.getTabs(locale: locale)
        } catch {
            Logger.navigation.error("\(RPCFunction.getTabs.rawValue, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            showFallback(locale: locale)
            return
        }
        // A response this build cannot show is unusable: the error screen
        // shows even when cached tabs exist (guide 5.3 rule 5).
        guard show(response) else {
            state = .error
            return
        }
        do {
            try cache.save(response, locale: locale)
        } catch {
            Logger.navigation.error("Could not cache the tabs: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Error screen retry.
    func retry() async {
        state = .loading
        await load()
    }

    /// After a failed fetch: keep tabs already showing, else the cached tabs,
    /// else the error screen (guide 5.3 rule 4).
    private func showFallback(locale: String) {
        if state == .tabs { return }
        if let cached = cache.load(locale: locale), show(cached) { return }
        state = .error
    }

    /// Shows the first five tabs whose root screens this build registers,
    /// keeping each tab's coordinator and stack while its root screen key
    /// stays the same, and the selected tab. False when no tab can be shown.
    private func show(_ response: TabsResponse) -> Bool {
        if response.tabs.count > Self.maximumTabs {
            let dropped = response.tabs.dropFirst(Self.maximumTabs).map(\.id).joined(separator: ", ")
            Logger.navigation.error("Dropped tabs beyond \(Self.maximumTabs): \(dropped, privacy: .public)")
        }
        var shown: [TabCoordinator] = []
        for item in response.tabs.prefix(Self.maximumTabs) {
            if let existing = tabs.first(where: { $0.id == item.id && $0.root.key == item.screen.key }) {
                existing.update(from: item)
                shown.append(existing)
            } else if registry.resolve(item.screen) != nil {
                shown.append(TabCoordinator(item: item, context: screens))
            } else {
                Logger.navigation.error("Dropped tab \(item.id, privacy: .public): its screen is not registered")
            }
        }
        guard !shown.isEmpty else { return false }
        tabs = shown
        if !shown.contains(where: { $0.id == selectedTabID }) {
            selectedTabID = shown.first?.id
        }
        state = .tabs
        return true
    }
}
