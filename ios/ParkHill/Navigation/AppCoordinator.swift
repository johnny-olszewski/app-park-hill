import Observation
import OSLog
import SwiftUI

/// Owns launch and what the app shows at its root (guide 5.1, 5.3). The
/// signed-in state arrives in IOS-006.
@MainActor
@Observable
final class AppCoordinator {
    enum State {
        case loading
        case screen(ResolvedScreen)
        case error
    }

    private(set) var state: State = .loading

    private let backend: any BackendService
    private let registry: ScreenRegistry
    private let cache: EntryCache
    private let locale: () -> String
    private var wasInBackground = false

    init(
        backend: any BackendService,
        registry: ScreenRegistry,
        cache: EntryCache,
        locale: @escaping () -> String = { AppLocale.current() }
    ) {
        self.backend = backend
        self.registry = registry
        self.cache = cache
        self.locale = locale
    }

    /// Launch: fetch the entry screen.
    func start() async {
        state = .loading
        await loadEntry()
    }

    /// Error screen retry.
    func retry() async {
        state = .loading
        await loadEntry()
    }

    /// Refetches when the app returns to the foreground (guide 5.3 rule 6).
    func scenePhaseChanged(to phase: ScenePhase) async {
        switch phase {
        case .background:
            wasInBackground = true
        case .active where wasInBackground:
            wasInBackground = false
            await loadEntry()
        default:
            break
        }
    }

    private func loadEntry() async {
        let locale = locale()
        let envelope: ScreenEnvelope
        do {
            envelope = try await backend.getEntry(locale: locale)
        } catch {
            Logger.navigation.error("get_entry failed: \(String(describing: error), privacy: .public)")
            showFallback(locale: locale)
            return
        }

        // A response this build cannot show is unusable: the error screen
        // shows even when a cached entry exists (guide 5.3 rule 5).
        guard let screen = registry.resolve(envelope) else {
            state = .error
            return
        }
        state = .screen(screen)
        do {
            try cache.save(envelope, locale: locale)
        } catch {
            Logger.navigation.error("Could not cache the entry screen: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// After a failed fetch: keep a screen already showing, else the last good
    /// cached entry, else the error screen (guide 5.3 rule 4).
    private func showFallback(locale: String) {
        if case .screen = state { return }
        if let cached = cache.load(locale: locale), let screen = registry.resolve(cached) {
            state = .screen(screen)
        } else {
            state = .error
        }
    }
}
