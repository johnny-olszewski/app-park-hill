import Foundation
import Testing
@testable import ParkHill

/// The signed-in shell: tabs from get_tabs, dropping, cache and selection
/// (IOS-008 AC1, AC4 to AC6, AC11, AC12).
@MainActor
struct ShellCoordinatorTests {
    private let cache = TabsCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))

    private func makeShell(_ backend: StubBackendService) -> ShellCoordinator {
        var registry = ScreenRegistry()
        registry.registerSharedScreens(auth: StubAuthService())
        let screenCache = ScreenCache(directory: cache.directory.appending(path: "screens"))
        return ShellCoordinator(backend: backend, registry: registry, cache: cache, screenCache: screenCache, locale: { "en" })
    }

    private func backend(_ results: Result<TabsResponse, BackendError>...) -> StubBackendService {
        let backend = StubBackendService(environment: .init(name: "Stub", backend: nil))
        for result in results { backend.enqueueTabs(result) }
        return backend
    }

    private let homeAndCommunity = TabsResponse.tabs(("home", "home.root"), ("community", "community.home"))

    @Test func showsTheTabsInBackendOrderAndSelectsTheFirst() async {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let shell = makeShell(backend(.success(.tabs(("community", "community.home"), ("home", "home.root")))))

        await shell.load()

        #expect(shell.state == .tabs)
        #expect(shell.tabs.map(\.id) == ["community", "home"])
        #expect(shell.tabs.map(\.title) == ["Community", "Home"])
        #expect(shell.selectedTabID == "community")
    }

    @Test func aTabWithAnUnregisteredScreenIsDropped() async {
        let shell = makeShell(backend(.success(.tabs(("future", "future.root"), ("home", "home.root")))))
        await shell.load()
        #expect(shell.tabs.map(\.id) == ["home"])
    }

    @Test func noShowableTabShowsTheErrorEvenWithACache() async throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        try cache.save(homeAndCommunity, locale: "en")
        let shell = makeShell(backend(.success(.tabs(("future", "future.root")))))
        await shell.load()
        #expect(shell.state == .error)
    }

    @Test func atMostFiveTabsAreShown() async {
        let six = TabsResponse.tabs(("a", "home.root"), ("b", "home.root"), ("c", "home.root"), ("d", "home.root"), ("e", "home.root"), ("f", "home.root"))
        let shell = makeShell(backend(.success(six)))
        await shell.load()
        #expect(shell.tabs.map(\.id) == ["a", "b", "c", "d", "e"])
    }

    @Test func aFailureShowsTheCachedTabs() async throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let online = makeShell(backend(.success(homeAndCommunity)))
        await online.load()
        #expect(cache.load(locale: "en") == homeAndCommunity)

        let offline = makeShell(backend(.failure(.network)))
        await offline.load()
        #expect(offline.state == .tabs)
        #expect(offline.tabs.map(\.id) == ["home", "community"])
    }

    @Test func aFailureWithoutACacheShowsTheErrorAndRetryRecovers() async {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let shell = makeShell(backend(.failure(.network), .success(homeAndCommunity)))
        await shell.load()
        #expect(shell.state == .error)

        await shell.retry()
        #expect(shell.state == .tabs)
    }

    @Test func refreshKeepsTheSelectedTabAndEachTabsStack() async throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let shell = makeShell(backend(.success(homeAndCommunity), .success(.tabs(("home", "home.root"), ("community", "community.home")))))
        await shell.load()
        shell.selectedTabID = "community"
        let community = try #require(shell.tabs.last)
        #expect(community.push(ScreenEnvelope(key: "home.root", data: .object([:]))))

        await shell.load()

        #expect(shell.selectedTabID == "community")
        #expect(shell.tabs.last === community)
        #expect(community.path.count == 1)
    }

    @Test func aFailedRefreshKeepsTheTabsShowing() async {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let shell = makeShell(backend(.success(homeAndCommunity), .failure(.network)))
        await shell.load()
        await shell.load()
        #expect(shell.state == .tabs)
    }

    @Test func aRemovedSelectedTabSelectsTheFirst() async {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let shell = makeShell(backend(.success(homeAndCommunity), .success(.tabs(("home", "home.root")))))
        await shell.load()
        shell.selectedTabID = "community"
        await shell.load()
        #expect(shell.selectedTabID == "home")
    }

    @Test func eachTabKeepsItsOwnStackWhenSwitching() async throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let shell = makeShell(backend(.success(homeAndCommunity)))
        await shell.load()
        let home = try #require(shell.tabs.first)
        let community = try #require(shell.tabs.last)

        #expect(home.push(ScreenEnvelope(key: "community.home", data: .object([:]))))
        shell.selectedTabID = "community"
        shell.selectedTabID = "home"

        #expect(home.path.count == 1)
        #expect(community.path.isEmpty)
        home.pop()
        #expect(home.path.isEmpty)
    }

    @Test func pushAndPresentRefuseScreensThisBuildCannotShow() async throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let shell = makeShell(backend(.success(homeAndCommunity)))
        await shell.load()
        let home = try #require(shell.tabs.first)
        let future = ScreenEnvelope(key: "future.screen", data: .object([:]))

        #expect(!home.push(future))
        #expect(!home.present(future))
        #expect(home.present(ScreenEnvelope(key: "home.root", data: .object([:]))))
        home.dismiss()
        #expect(home.presented == nil)
    }
}
