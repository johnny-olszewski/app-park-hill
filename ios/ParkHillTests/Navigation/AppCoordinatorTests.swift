import Foundation
import SwiftUI
import Testing
@testable import ParkHill

@MainActor
struct AppCoordinatorTests {
    private let cache = EntryCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))

    private func makeCoordinator(_ backend: StubBackendService) -> AppCoordinator {
        var registry = ScreenRegistry()
        registry.registerSharedScreens()
        return AppCoordinator(backend: backend, registry: registry, cache: cache, locale: { "en" })
    }

    private func shownKey(_ coordinator: AppCoordinator) -> String? {
        if case .screen(let screen) = coordinator.state { return screen.key }
        return nil
    }

    private func isError(_ coordinator: AppCoordinator) -> Bool {
        if case .error = coordinator.state { return true }
        return false
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
}
