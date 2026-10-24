import Observation
import OSLog

/// What a backend screen needs to fetch, show and cache itself.
@MainActor
struct ScreenContext {
    let backend: any BackendService
    let registry: ScreenRegistry
    let cache: ScreenCache
    let locale: () -> String
}

/// One shown backend screen: its key and params, and what it shows now.
/// Fetches with `get_screen`, refreshes on demand, and falls back to the last
/// good copy for its key and params, else the error screen (guide 5.3 rules 4
/// and 10).
@MainActor
@Observable
final class ScreenModel: Identifiable {
    enum State {
        case loading
        case screen(ResolvedScreen)
        case error
    }

    let key: String
    let params: [String: JSONValue]
    private(set) var state: State

    private let context: ScreenContext

    /// A screen whose content is already here, such as a tab root embedded in
    /// `get_tabs`. Kept as its last good copy.
    init(envelope: ScreenEnvelope, params: [String: JSONValue] = [:], context: ScreenContext) {
        key = envelope.key
        self.params = params
        self.context = context
        state = .loading
        show(envelope, locale: context.locale())
    }

    /// A screen still to fetch, such as the target of a `navigate` action.
    /// It shows the loading state until `load()` finishes.
    init(key: String, params: [String: JSONValue], context: ScreenContext) {
        self.key = key
        self.params = params
        self.context = context
        state = .loading
    }

    /// The envelope showing now, if any.
    var envelope: ScreenEnvelope? {
        if case .screen(let screen) = state { return screen.envelope }
        return nil
    }

    /// Fetches the screen. Also pull to refresh: a failure keeps a screen
    /// already showing.
    func load() async {
        let locale = context.locale()
        do {
            let envelope = try await context.backend.getScreen(key: key, locale: locale, params: params)
            show(envelope, locale: locale)
        } catch {
            Logger.navigation.error("\(RPCFunction.getScreen.rawValue, privacy: .public) \(self.key, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            showFallback(locale: locale)
        }
    }

    /// Error screen retry.
    func retry() async {
        state = .loading
        await load()
    }

    /// Shows a newer copy of the same screen, such as a refreshed tab root.
    func update(_ envelope: ScreenEnvelope) {
        guard envelope != self.envelope else { return }
        show(envelope, locale: context.locale())
    }

    /// Shows `envelope` and keeps it as the last good copy. A screen this
    /// build cannot show falls back like a failed fetch.
    private func show(_ envelope: ScreenEnvelope, locale: String) {
        guard let screen = context.registry.resolve(envelope) else {
            showFallback(locale: locale)
            return
        }
        state = .screen(screen)
        do {
            try context.cache.save(envelope, params: params, locale: locale)
        } catch {
            Logger.navigation.error("Could not cache \(envelope.key, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Keeps a screen already showing, else shows the cached copy, else the
    /// error screen.
    private func showFallback(locale: String) {
        if case .screen = state { return }
        if let cached = context.cache.load(key: key, params: params, locale: locale),
           let screen = context.registry.resolve(cached) {
            state = .screen(screen)
        } else {
            state = .error
        }
    }
}
