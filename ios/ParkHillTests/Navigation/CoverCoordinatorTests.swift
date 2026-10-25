import Foundation
import SwiftUI
import Testing
@testable import ParkHill

/// Full-screen covers: fetched fresh, their own stack, closing drops them
/// (IOS-025 AC3 to AC5).
@MainActor
struct CoverCoordinatorTests {
    private let cache = ScreenCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
    private let backend = StubBackendService(environment: .init(name: "Stub", backend: nil))

    private struct TestData: Decodable { let title: String }

    private var context: ScreenContext {
        var registry = ScreenRegistry()
        registry.register("test.screen", data: TestData.self) { _ in EmptyView() }
        return ScreenContext(backend: backend, registry: registry, cache: cache, locale: { "en" })
    }

    private static func screen(_ title: String) -> ScreenEnvelope {
        ScreenEnvelope(key: "test.screen", data: .object(["title": .string(title)]))
    }

    private func navigate(_ presentation: NavigateActionPresentation, to key: String = "test.screen") -> Action {
        .navigate(NavigateAction(type: .navigate, screenKey: key, params: .object([:]), presentation: presentation))
    }

    private func tab() -> TabCoordinator {
        TabCoordinator(item: TabItem(id: "t", title: "T", iconKey: "tab.t", screen: Self.screen("Root")), context: context)
    }

    @Test func aCoverOpensOverALoadingStateThenItsScreen() async throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        backend.enqueueScreen(.success(Self.screen("Browse")))
        let tab = tab()

        tab.perform(navigate(.fullScreenCover))
        let cover = try #require(tab.cover)
        guard case .loading = cover.root.state else { Issue.record("not loading first"); return }
        #expect(tab.path.isEmpty, "a cover is not pushed")

        await cover.root.load()
        #expect(cover.root.envelope == Self.screen("Browse"))
    }

    @Test func pushesInsideACoverGoOnItsOwnStack() async throws {
        let tab = tab()
        tab.perform(navigate(.fullScreenCover))
        let cover = try #require(tab.cover)

        cover.perform(navigate(.push))
        #expect(cover.path.count == 1)
        #expect(tab.path.isEmpty)

        cover.perform(navigate(.push, to: "future.screen"))
        cover.perform(navigate(.fullScreenCover))
        #expect(cover.path.count == 1, "unregistered targets and nested covers do nothing")
    }

    @Test func closingDropsTheCoverAndReopeningFetchesAgain() async throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        backend.enqueueScreen(.success(Self.screen("First")), .success(Self.screen("Second")))
        let tab = tab()
        tab.perform(navigate(.fullScreenCover))
        let first = try #require(tab.cover)
        await first.root.load()

        tab.closeCover()
        #expect(tab.cover == nil)

        tab.perform(navigate(.fullScreenCover))
        let second = try #require(tab.cover)
        #expect(second !== first)
        await second.root.load()
        #expect(second.root.envelope == Self.screen("Second"))
    }

    @Test func anUnregisteredCoverTargetOpensNothing() {
        let tab = tab()
        tab.perform(navigate(.fullScreenCover, to: "future.screen"))
        #expect(tab.cover == nil)
    }
}
