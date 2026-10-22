import Observation
import OSLog
import SwiftUI

/// Owns launch and the app's root (guide 5.1, 5.3). The signed-in shell of
/// tabs is the root; the signed-out entry screen is presented over it as a
/// full-screen cover, shown and hidden by the auth state stream.
@MainActor
@Observable
final class AppCoordinator {
    /// What the entry cover shows.
    enum EntryState {
        case loading
        case screen(ResolvedScreen)
        case error
    }

    /// True until the stored session has been checked at launch.
    private(set) var isLaunching = true
    /// The signed-in user, or nil when there is none. Kept while the entry
    /// cover animates in, then cleared.
    private(set) var signedInUser: AuthUser?
    /// The signed-in user's tabs, created at sign-in and dropped with the user.
    private(set) var shell: ShellCoordinator?
    /// Whether the entry cover is presented.
    private(set) var isEntryPresented = false
    private(set) var entry: EntryState = .loading
    /// Why the user was last signed out, for the sign-in screen's notice.
    private(set) var signOutReason: SignOutReason?

    private let backend: any BackendService
    private let auth: any AuthService
    private let registry: ScreenRegistry
    private let cache: EntryCache
    private let tabsCache: TabsCache
    private let locale: () -> String
    private var wasInBackground = false
    private var authObservation: Task<Void, Never>?

    init(
        backend: any BackendService,
        auth: any AuthService,
        registry: ScreenRegistry,
        cache: EntryCache,
        tabsCache: TabsCache = .standard,
        locale: @escaping () -> String = { AppLocale.current() }
    ) {
        self.backend = backend
        self.auth = auth
        self.registry = registry
        self.cache = cache
        self.tabsCache = tabsCache
        self.locale = locale
    }

    /// Launch: restore the session (specs/AUTH.md 4.1), then follow the auth
    /// state for the rest of the app's life.
    func start() async {
        switch await auth.restoreSession() {
        case .signedIn(let user):
            signedInUser = user
            let shell = makeShell()
            isLaunching = false
            await shell.load()
        case .signedOut(let reason):
            signOutReason = reason
            // On a cold start the cover is simply there; it does not slide in.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                isEntryPresented = true
                isLaunching = false
            }
            await loadEntry()
        }
        observeAuth()
    }

    /// Error screen retry.
    func retry() async {
        entry = .loading
        await loadEntry()
    }

    func signOut() async {
        await auth.signOut()
    }

    /// The entry cover finished presenting: drop the signed-in content behind
    /// it, so nothing about the last user stays on screen.
    func entryDidAppear() {
        if isEntryPresented {
            signedInUser = nil
            shell = nil
        }
    }

    /// Return to the foreground refetches (guide 5.3 rule 6). Signed in, the
    /// tabs request also checks the session is still active, so a disabled
    /// account is signed out on its next foreground (specs/AUTH.md 4.3).
    func scenePhaseChanged(to phase: ScenePhase) async {
        switch phase {
        case .background:
            wasInBackground = true
        case .active where wasInBackground:
            wasInBackground = false
            if isEntryPresented {
                await loadEntry()
            } else if let shell {
                await shell.load()
            }
        default:
            break
        }
    }

    func handle(_ authState: AuthState) async {
        switch authState {
        case .signedIn(let user):
            // The shell is in place under the cover before it hides. A new
            // user (such as a mock persona switch) gets a new shell.
            signOutReason = nil
            let isNewUser = user != signedInUser || shell == nil
            signedInUser = user
            let shell = isNewUser ? makeShell() : shell
            isEntryPresented = false
            if isNewUser {
                await shell?.load()
            }
        case .signedOut(let reason):
            guard !isEntryPresented, !isLaunching else { return }
            signOutReason = reason
            entry = .loading
            isEntryPresented = true
            await loadEntry()
        }
    }

    private func makeShell() -> ShellCoordinator {
        let shell = ShellCoordinator(backend: backend, registry: registry, cache: tabsCache, locale: locale)
        self.shell = shell
        return shell
    }

    private func observeAuth() {
        authObservation?.cancel()
        let changes = auth.stateChanges()
        authObservation = Task { [weak self] in
            for await change in changes {
                await self?.handle(change)
            }
        }
    }

    private func loadEntry() async {
        let locale = locale()
        let envelope: ScreenEnvelope
        do {
            envelope = try await backend.getEntry(locale: locale)
        } catch {
            Logger.navigation.error("\(RPCFunction.getEntry.rawValue, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            showFallback(locale: locale)
            return
        }

        // A response this build cannot show is unusable: the error screen
        // shows even when a cached entry exists (guide 5.3 rule 5).
        guard let screen = registry.resolve(envelope) else {
            entry = .error
            return
        }
        entry = .screen(screen)
        do {
            try cache.save(envelope, locale: locale)
        } catch {
            Logger.navigation.error("Could not cache the entry screen: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// After a failed fetch: keep a screen already showing, else the last good
    /// cached entry, else the error screen (guide 5.3 rule 4).
    private func showFallback(locale: String) {
        if case .screen = entry { return }
        if let cached = cache.load(locale: locale), let screen = registry.resolve(cached) {
            entry = .screen(screen)
        } else {
            entry = .error
        }
    }
}
