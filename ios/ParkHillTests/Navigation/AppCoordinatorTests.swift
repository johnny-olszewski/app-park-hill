import Foundation
import SwiftUI
import Testing
@testable import ParkHill

@MainActor
struct AppCoordinatorTests {
    private let cache = EntryCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
    private let tabsCache = TabsCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))

    private func makeCoordinator(_ backend: StubBackendService, auth: StubAuthService = StubAuthService()) -> AppCoordinator {
        var registry = ScreenRegistry()
        registry.registerSharedScreens(auth: auth)
        return AppCoordinator(backend: backend, auth: auth, registry: registry, cache: cache, tabsCache: tabsCache, locale: { "en" })
    }

    /// The entry screen key, when the entry cover is presented and shows one.
    private func shownKey(_ coordinator: AppCoordinator) -> String? {
        guard coordinator.isEntryPresented, case .screen(let screen) = coordinator.entry else { return nil }
        return screen.key
    }

    private func isError(_ coordinator: AppCoordinator) -> Bool {
        guard coordinator.isEntryPresented, case .error = coordinator.entry else { return false }
        return true
    }

    // MARK: Launch

    @Test func launchShowsTheEntryScreenAndCachesIt() async {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let backend = StubBackendService(entry: .success(.signIn(title: "Sign in")))
        let coordinator = makeCoordinator(backend)

        await coordinator.start()

        #expect(shownKey(coordinator) == "auth.sign_in")
        #expect(backend.entryCalls == ["en"])
        #expect(cache.load(locale: "en") == .signIn(title: "Sign in"))
    }

    @Test func failureWithACacheShowsTheCachedScreen() async throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        try cache.save(.signIn(title: "Cached"), locale: "en")
        let coordinator = makeCoordinator(StubBackendService(entry: .failure(.network)))

        await coordinator.start()

        #expect(shownKey(coordinator) == "auth.sign_in")
    }

    @Test func failureWithoutACacheShowsTheErrorScreen() async {
        let coordinator = makeCoordinator(StubBackendService(entry: .failure(.network)))
        await coordinator.start()
        #expect(isError(coordinator))
    }

    @Test func cachedEnvelopeThisBuildCannotShowCountsAsNoCache() async throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        try cache.save(ScreenEnvelope(key: "future.screen", data: .object([:])), locale: "en")
        let coordinator = makeCoordinator(StubBackendService(entry: .failure(.server)))

        await coordinator.start()

        #expect(isError(coordinator))
    }

    // MARK: Unknown keys

    @Test func unregisteredEntryKeyShowsTheErrorScreen() async {
        let coordinator = makeCoordinator(StubBackendService(entry: .success(ScreenEnvelope(key: "future.screen", data: .object([:])))))
        await coordinator.start()
        #expect(isError(coordinator))
    }

    @Test func unregisteredEntryKeyIgnoresTheCacheAndIsNotCached() async throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        try cache.save(.signIn(title: "Cached"), locale: "en")
        let future = ScreenEnvelope(key: "future.screen", data: .object([:]))
        let coordinator = makeCoordinator(StubBackendService(entry: .success(future)))

        await coordinator.start()

        #expect(isError(coordinator))
        #expect(cache.load(locale: "en") == .signIn(title: "Cached"))
    }

    // MARK: Retry and foreground

    @Test func retryAfterAnErrorShowsTheScreen() async {
        let backend = StubBackendService(entry: .failure(.network), .success(.signIn()))
        let coordinator = makeCoordinator(backend)

        await coordinator.start()
        #expect(isError(coordinator))

        await coordinator.retry()
        #expect(shownKey(coordinator) == "auth.sign_in")
        #expect(backend.entryCalls.count == 2)
    }

    @Test func returningToTheForegroundRefetchesAndCachesTheNewScreen() async {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let backend = StubBackendService(entry: .success(.signIn(title: "Sign in")), .success(.signIn(title: "Log in")))
        let coordinator = makeCoordinator(backend)
        await coordinator.start()

        await coordinator.scenePhaseChanged(to: .inactive)
        await coordinator.scenePhaseChanged(to: .background)
        await coordinator.scenePhaseChanged(to: .inactive)
        await coordinator.scenePhaseChanged(to: .active)

        #expect(backend.entryCalls.count == 2)
        #expect(cache.load(locale: "en") == .signIn(title: "Log in"))
    }

    @Test func becomingActiveWithoutBackgroundingDoesNotRefetch() async {
        let backend = StubBackendService(entry: .success(.signIn()))
        let coordinator = makeCoordinator(backend)
        await coordinator.start()

        await coordinator.scenePhaseChanged(to: .inactive)
        await coordinator.scenePhaseChanged(to: .active)

        #expect(backend.entryCalls.count == 1)
    }

    @Test func foregroundRefreshFailureKeepsTheCurrentScreen() async {
        let backend = StubBackendService(entry: .success(.signIn()), .failure(.network))
        let coordinator = makeCoordinator(backend)
        await coordinator.start()

        await coordinator.scenePhaseChanged(to: .background)
        await coordinator.scenePhaseChanged(to: .active)

        #expect(backend.entryCalls.count == 2)
        #expect(shownKey(coordinator) == "auth.sign_in")
    }

    // MARK: Signed in (IOS-006)

    private let attendee = AuthUser(id: "u1", email: "attendee@parkhill.test")

    private let tabs = TabsResponse.tabs(("home", "home.root"), ("community", "community.home"))

    @Test func launchWithASessionGoesStraightToTheTabsWithoutGetEntry() async {
        let backend = StubBackendService(entry: .success(.signIn()))
        backend.enqueueTabs(.success(tabs))
        let coordinator = makeCoordinator(backend, auth: StubAuthService(restore: .signedIn(attendee)))

        await coordinator.start()

        #expect(coordinator.signedInUser == attendee)
        #expect(coordinator.shell?.tabs.map(\.id) == ["home", "community"])
        #expect(!coordinator.isEntryPresented)
        #expect(!coordinator.isLaunching)
        #expect(backend.entryCalls.isEmpty)
    }

    @Test func launchSignedOutPresentsTheEntryCover() async {
        let coordinator = makeCoordinator(StubBackendService(entry: .success(.signIn())))
        #expect(coordinator.isLaunching)

        await coordinator.start()

        #expect(!coordinator.isLaunching)
        #expect(coordinator.isEntryPresented)
        #expect(coordinator.signedInUser == nil)
    }

    @Test func signingInShowsTheTabs() async {
        let auth = StubAuthService()
        let backend = StubBackendService(entry: .success(.signIn()))
        backend.enqueueTabs(.success(tabs))
        let coordinator = makeCoordinator(backend, auth: auth)
        await coordinator.start()

        await coordinator.handle(.signedIn(attendee))

        #expect(coordinator.signedInUser == attendee)
        #expect(coordinator.shell?.state == .tabs)
        #expect(!coordinator.isEntryPresented, "the cover hides over the signed-in root")
        #expect(coordinator.signOutReason == nil)
    }

    @Test func signOutReturnsToTheEntryScreen() async {
        let backend = StubBackendService(entry: .success(.signIn()))
        let auth = StubAuthService(restore: .signedIn(attendee))
        let coordinator = makeCoordinator(backend, auth: auth)
        await coordinator.start()

        await coordinator.handle(.signedOut(.userRequest))

        #expect(shownKey(coordinator) == "auth.sign_in")
        #expect(coordinator.signOutReason == .userRequest)
        #expect(backend.entryCalls.count == 1)
        #expect(coordinator.signedInUser == attendee, "kept while the cover animates in")

        coordinator.entryDidAppear()
        #expect(coordinator.signedInUser == nil, "cleared once the cover covers it")
        #expect(coordinator.shell == nil, "the tabs go with the user")
    }

    @Test func entryAppearingWhileSignedInKeepsTheUser() async {
        let coordinator = makeCoordinator(
            StubBackendService(entry: .success(.signIn())),
            auth: StubAuthService(restore: .signedIn(attendee))
        )
        await coordinator.start()
        coordinator.entryDidAppear()
        #expect(coordinator.signedInUser == attendee)
    }

    @Test func accessEndingReturnsToSignInWithTheSessionEndedReason() async {
        let coordinator = makeCoordinator(
            StubBackendService(entry: .success(.signIn())),
            auth: StubAuthService(restore: .signedIn(attendee))
        )
        await coordinator.start()

        await coordinator.handle(.signedOut(.sessionEnded))

        #expect(shownKey(coordinator) == "auth.sign_in")
        #expect(coordinator.signOutReason == .sessionEnded)
    }

    @Test func signOutAsksTheAuthService() async {
        let auth = StubAuthService(restore: .signedIn(attendee))
        let coordinator = makeCoordinator(StubBackendService(entry: .success(.signIn())), auth: auth)
        await coordinator.start()

        await coordinator.signOut()

        #expect(auth.signOuts == 1)
    }

    @Test func foregroundWhileSignedInRefreshesTheTabs() async {
        let backend = StubBackendService(entry: .success(.signIn()))
        backend.enqueueTabs(.success(tabs))
        let coordinator = makeCoordinator(backend, auth: StubAuthService(restore: .signedIn(attendee)))
        await coordinator.start()

        await coordinator.scenePhaseChanged(to: .background)
        await coordinator.scenePhaseChanged(to: .active)

        #expect(backend.tabsCalls == ["en", "en"], "get_tabs also checks the session is still active")
        #expect(backend.entryCalls.isEmpty)
    }

    @Test func aDifferentUserGetsNewTabsAndTheSameUserKeepsThem() async {
        let backend = StubBackendService(entry: .success(.signIn()))
        backend.enqueueTabs(.success(tabs))
        let coordinator = makeCoordinator(backend, auth: StubAuthService(restore: .signedIn(attendee)))
        await coordinator.start()
        let first = coordinator.shell

        await coordinator.handle(.signedIn(attendee))
        #expect(coordinator.shell === first)

        await coordinator.handle(.signedIn(AuthUser(id: "u2", email: nil)))
        #expect(coordinator.shell !== first)
        #expect(backend.tabsCalls.count == 2)
    }
}
