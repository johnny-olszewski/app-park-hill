import Foundation
import Testing
@testable import ParkHill

/// Community home's state inference and unusable data (IOS-010 AC2, AC6).
@MainActor
struct CommunityHomeTests {
    private let empty = EmptyState(title: "None yet", message: "Ask staff.")
    private let list = GroupList(title: "My groups", rows: [])
    private let group = GroupDetail(
        groupId: "g", title: "Group", description: "", meeting: "", location: "",
        leadersLine: "Leaders: none yet", membersTitle: "Members", members: []
    )

    @Test func groupWinsOverMyGroupsAndEmpty() {
        #expect(CommunityHomeState(CommunityHomeData(group: group, myGroups: list, empty: empty)) == .group(group))
    }

    @Test func myGroupsWinsOverEmpty() {
        #expect(CommunityHomeState(CommunityHomeData(group: nil, myGroups: list, empty: empty)) == .myGroups(list))
    }

    @Test func emptyAlone() {
        #expect(CommunityHomeState(CommunityHomeData(group: nil, myGroups: nil, empty: empty)) == .empty(empty))
    }

    @Test func nonePresentIsUnusable() {
        #expect(CommunityHomeState(CommunityHomeData(group: nil, myGroups: nil, empty: nil)) == nil)
    }

    @Test(arguments: ["attendee", "member_one", "member_two", "leader", "staff", "admin"])
    func everyPersonasRecordedHomeHasItsState(persona: String) throws {
        let envelope = try JSONDecoder().decode(ScreenEnvelope.self, from: TestMockResponses.data("\(persona)/get_screen.community.home.json"))
        let data = try JSONDecoder().decode(CommunityHomeData.self, from: JSONEncoder().encode(envelope.data))
        let state = try #require(CommunityHomeState(data))
        switch (persona, state) {
        case ("attendee", .empty), ("staff", .empty), ("member_two", .myGroups),
             ("member_one", .group), ("leader", .group), ("admin", .group):
            break
        default:
            Issue.record("\(persona) has \(state)")
        }
    }

    private func registry() -> ScreenRegistry {
        var registry = ScreenRegistry()
        registry.registerSharedScreens(auth: StubAuthService())
        return registry
    }

    private static let unusable = ScreenEnvelope(key: "community.home", data: .object([:]))

    @Test func unusableHomeDoesNotResolve() {
        #expect(registry().resolve(Self.unusable) == nil)
    }

    @Test func unusableHomeShowsTheCachedCopyElseTheError() async throws {
        let cache = ScreenCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let backend = StubBackendService(environment: .init(name: "Stub", backend: nil))
        let context = ScreenContext(backend: backend, registry: registry(), cache: cache, locale: { "en" })

        let noCache = ScreenModel(envelope: Self.unusable, context: context)
        guard case .error = noCache.state else { Issue.record("no error screen"); return }

        let good = try JSONDecoder().decode(ScreenEnvelope.self, from: TestMockResponses.data("attendee/get_screen.community.home.json"))
        _ = ScreenModel(envelope: good, context: context)
        backend.enqueueScreen(.success(Self.unusable))
        let withCache = ScreenModel(key: "community.home", params: [:], context: context)
        await withCache.load()
        #expect(withCache.envelope == good)
    }

    @Test func aTabWhoseRootCannotBeShownStaysAsATab() async throws {
        let cache = TabsCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let backend = StubBackendService(environment: .init(name: "Stub", backend: nil))
        backend.enqueueTabs(.success(.tabs(("home", "home.root"), ("community", "community.home"))))
        let shell = ShellCoordinator(
            backend: backend, registry: registry(), cache: cache,
            screenCache: ScreenCache(directory: cache.directory.appending(path: "screens")), locale: { "en" }
        )
        await shell.load()
        #expect(shell.tabs.map(\.id) == ["home", "community"])
        guard case .error = try #require(shell.tabs.last).root.state else { Issue.record("no error screen"); return }
    }
}
