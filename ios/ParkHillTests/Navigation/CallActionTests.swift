import Foundation
import SwiftUI
import Testing
@testable import ParkHill

/// `call` actions and the lost-access rule (IOS-026 AC1, AC3 to AC5), with
/// the buttons the backend records for `leader`.
@MainActor
struct CallActionTests {
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

    private func tab() -> TabCoordinator {
        TabCoordinator(item: TabItem(id: "t", title: "T", iconKey: "tab.t", screen: Self.screen("Root")), context: context)
    }

    /// `leader`'s recorded group detail, from Community home.
    private func leaderGroup() throws -> GroupDetail {
        let envelope = try JSONDecoder().decode(ScreenEnvelope.self, from: TestMockResponses.data("leader/get_screen.community.home.json"))
        let data = try JSONDecoder().decode(CommunityHomeData.self, from: JSONEncoder().encode(envelope.data))
        return try #require(data.group)
    }

    private func call(_ button: ActionButton?) throws -> CallAction {
        guard case .call(let call) = try #require(button).action else { throw CancellationError() }
        return call
    }

    /// A pushed screen showing `title`.
    private func pushed(on tab: TabCoordinator, _ title: String) throws -> ScreenModel {
        #expect(tab.push(Self.screen(title)))
        return try #require(tab.path.last?.screen)
    }

    // AC1: the backend's confirmation comes first; cancelling calls nothing.

    @Test func aCallWithConfirmWaitsForTheBackendsWording() throws {
        let tab = tab()
        let leave = try call(leaderGroup().leave)

        tab.perform(.call(leave), from: tab.root)

        let pending = try #require(tab.pendingCall)
        #expect(pending.confirm == leave.confirm)
        #expect(pending.confirm.title == "Leave Tuesday Night Group?")
        #expect(pending.isDestructive)
        #expect(backend.calls.isEmpty)
    }

    @Test func cancellingCallsNothing() async throws {
        let tab = tab()
        tab.perform(.call(try call(leaderGroup().leave)), from: tab.root)
        tab.cancelCall()
        await Task.yield()
        #expect(tab.pendingCall == nil)
        #expect(backend.calls.isEmpty)
    }

    @Test func confirmingCallsTheFunctionWithItsParamsAndTheLocale() async throws {
        let tab = tab()
        let leave = try call(leaderGroup().leave)
        backend.enqueueScreen(.success(Self.screen("Root")))

        await tab.run(leave, from: tab.root)

        #expect(backend.calls == [.init(function: "leave_group", params: leave.params.objectValue, locale: "en")])
    }

    @Test func refreshReloadsTheScreenTheCallCameFrom() async throws {
        let tab = tab()
        let remove = try call(leaderGroup().members.first { $0.remove != nil }?.remove)
        #expect(remove.onSuccess == .refresh)
        backend.enqueueScreen(.success(Self.screen("Refreshed")))

        await tab.run(remove, from: tab.root)

        #expect(tab.root.envelope == Self.screen("Refreshed"))
    }

    // AC3: leaving lands somewhere valid.

    @Test func dismissOnAPushedScreenClosesItAndRefreshesTheOneBelow() async throws {
        let tab = tab()
        let first = try pushed(on: tab, "First")
        let group = try pushed(on: tab, "Group")
        backend.enqueueScreen(.success(Self.screen("First, refreshed")))

        await tab.run(try call(leaderGroup().leave), from: group)

        #expect(tab.path.count == 1 && tab.path.first?.screen === first)
        #expect(first.envelope == Self.screen("First, refreshed"))
        #expect(tab.message == nil)
    }

    @Test func dismissOnTheTabRootRefreshesItInPlace() async throws {
        let tab = tab()
        backend.enqueueScreen(.success(Self.screen("Home, now empty")))

        await tab.run(try call(leaderGroup().leave), from: tab.root)

        #expect(tab.root.envelope == Self.screen("Home, now empty"))
        #expect(tab.path.isEmpty)
    }

    // AC4: lost access closes the screen, refreshes the one below and says why.

    @Test func aRefreshRefusedAsUnavailableClosesTheScreenAndShowsTheMessage() async throws {
        let tab = tab()
        let group = try pushed(on: tab, "Group")
        backend.enqueueScreen(.failure(.screenUnavailable(message: "You're no longer in this group.")), .success(Self.screen("Root, refreshed")))

        await group.load()
        await tab.refresh?.value

        #expect(tab.path.isEmpty)
        #expect(tab.root.envelope == Self.screen("Root, refreshed"))
        #expect(tab.message == "You're no longer in this group.")
    }

    @Test func lostAccessInsideACoverClosesItWhenItIsTheRoot() async throws {
        let tab = tab()
        backend.enqueueScreen(.failure(.screenUnavailable(message: "Gone.")), .success(Self.screen("Root")))
        tab.perform(.navigate(NavigateAction(type: .navigate, screenKey: "test.screen", params: .object([:]), presentation: .fullScreenCover)))
        let cover = try #require(tab.cover)

        await cover.root.load()

        #expect(tab.cover == nil)
        #expect(tab.message == "Gone.")
    }

    // AC5: a refused call says so and refreshes.

    @Test func aRefusedCallShowsTheBackendsMessageAndRefreshes() async throws {
        let tab = tab()
        backend.enqueueCall(.failure(.actionRefused(message: "You can't make this change anymore.")))
        backend.enqueueScreen(.success(Self.screen("Refreshed")))

        await tab.run(try call(leaderGroup().members.first { $0.remove != nil }?.remove), from: tab.root)

        #expect(tab.message == "You can't make this change anymore.")
        #expect(tab.root.envelope == Self.screen("Refreshed"))
    }

    @Test func aRefusedCallWhoseRefreshLosesAccessShowsOnlyThatMessage() async throws {
        let tab = tab()
        let group = try pushed(on: tab, "Group")
        backend.enqueueCall(.failure(.actionRefused(message: "You can't make this change anymore.")))
        backend.enqueueScreen(.failure(.screenUnavailable(message: "You're no longer in this group.")), .success(Self.screen("Root")))

        await tab.run(try call(leaderGroup().members.first { $0.remove != nil }?.remove), from: group)

        #expect(tab.path.isEmpty)
        #expect(tab.message == "You're no longer in this group.")
    }
}
