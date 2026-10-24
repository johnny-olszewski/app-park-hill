import SwiftUI
import Foundation
import Testing
@testable import ParkHill

/// Backend screens: refresh and the per-screen cache (IOS-009 AC4, AC5).
@MainActor
struct ScreenModelTests {
    private let cache = ScreenCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
    private let backend = StubBackendService(environment: .init(name: "Stub", backend: nil))

    private var context: ScreenContext {
        var registry = ScreenRegistry()
        registry.register("test.screen", data: TestData.self) { _ in EmptyView() }
        return ScreenContext(backend: backend, registry: registry, cache: cache, locale: { "en" })
    }

    private struct TestData: Decodable { let title: String }

    private static func screen(_ title: String) -> ScreenEnvelope {
        ScreenEnvelope(key: "test.screen", data: .object(["title": .string(title)]))
    }

    private static let params: [String: JSONValue] = ["id": .string("1")]

    private func tab() -> TabCoordinator {
        TabCoordinator(item: TabItem(id: "t", title: "T", iconKey: "tab.t", screen: Self.screen("Root")), context: context)
    }

    // AC4: pull to refresh shows the new data.

    @Test func refreshShowsTheNewData() async {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        backend.enqueueScreen(.success(Self.screen("Fresh")))
        let model = ScreenModel(envelope: Self.screen("Stale"), context: context)

        await model.load()

        #expect(model.envelope == Self.screen("Fresh"))
        #expect(backend.screenCalls == [.init(key: "test.screen", params: [:])])
    }

    @Test func aFailedRefreshKeepsTheScreenShowing() async {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        backend.enqueueScreen(.failure(.network))
        let model = ScreenModel(envelope: Self.screen("Shown"), context: context)
        await model.load()
        #expect(model.envelope == Self.screen("Shown"))
    }

    // AC5: a failed fetch shows the cached copy for that key and params, else
    // the error screen.

    @Test func aFailedFetchShowsTheCachedCopyForThatKeyAndParams() async throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        backend.enqueueScreen(.success(Self.screen("Online")), .failure(.network))
        let online = ScreenModel(key: "test.screen", params: Self.params, context: context)
        await online.load()

        let offline = ScreenModel(key: "test.screen", params: Self.params, context: context)
        await offline.load()
        #expect(offline.envelope == Self.screen("Online"))

        let otherParams = ScreenModel(key: "test.screen", params: ["id": .string("2")], context: context)
        await otherParams.load()
        guard case .error = otherParams.state else { Issue.record("other params used the cache"); return }
    }

    @Test func aFailedFetchWithoutACacheShowsTheErrorAndRetryRecovers() async {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        backend.enqueueScreen(.failure(.network), .success(Self.screen("Back")))
        let model = ScreenModel(key: "test.screen", params: Self.params, context: context)

        await model.load()
        guard case .error = model.state else { Issue.record("no error screen"); return }

        await model.retry()
        #expect(model.envelope == Self.screen("Back"))
    }

    @Test func aScreenThisBuildCannotShowFallsBackToTheCache() async {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        backend.enqueueScreen(.success(Self.screen("Good")), .success(ScreenEnvelope(key: "test.screen", data: .object([:]))))
        let first = ScreenModel(key: "test.screen", params: [:], context: context)
        await first.load()

        let second = ScreenModel(key: "test.screen", params: [:], context: context)
        await second.load()
        #expect(second.envelope == Self.screen("Good"))
    }

    @Test func theScreenCacheIsWipedWithTheUsersData() {
        #expect(ScreenCache.standard.directory.path.hasPrefix(CacheDirectory.url.path))
        #expect(LocalUserData.standard.directories.contains(CacheDirectory.url))
    }

    @Test func aTabRootKeepsItsStackWhenItsDataChanges() {
        let tab = tab()
        #expect(tab.push(Self.screen("Pushed")))
        tab.update(from: TabItem(id: "t", title: "T2", iconKey: "tab.t", screen: Self.screen("Root 2")))
        #expect(tab.root.envelope == Self.screen("Root 2"))
        #expect(tab.path.count == 1)
        #expect(tab.title == "T2")
    }
}
