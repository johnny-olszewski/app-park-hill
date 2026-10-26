import Foundation
import SwiftUI
import Testing
@testable import ParkHill

/// Edit mode's staging and batch (IOS-013 AC2 to AC5), with the recorded
/// detail of Tuesday Night Group as `leader` and as `staff` see it.
@MainActor
struct GroupEditStateTests {
    private static let tuesday = "d44d5b87-37ce-5db5-9e33-43f477b42f1e"

    private static func detail(_ path: String) throws -> GroupDetail {
        let envelope = try JSONDecoder().decode(ScreenEnvelope.self, from: TestMockResponses.data(path))
        let data = try JSONEncoder().encode(envelope.data)
        if let home = try? JSONDecoder().decode(CommunityHomeData.self, from: data), let group = home.group { return group }
        return try JSONDecoder().decode(GroupDetail.self, from: data)
    }

    private static func leader() throws -> GroupDetail { try detail("leader/get_screen.community.home.json") }
    private static func staff() throws -> GroupDetail { try detail("staff/get_screen.community.group@group_id=\(tuesday).json") }

    private static let emptyBatch: JSONValue = .object([
        "fields": .object([:]), "add": .array([]), "remove": .array([]), "make_leader": .array([]), "remove_leader": .array([]),
    ])

    @Test func nothingStagedSendsAnEmptyBatch() throws {
        let edit = GroupEditState(try Self.leader())
        #expect(edit.batch == Self.emptyBatch)
        #expect(edit.rows.map(\.id) == (try Self.leader()).members.map(\.userId))
    }

    @Test func theBatchCarriesOnlyChangedFieldsAndEveryStagedChange() throws {
        let detail = try Self.leader()
        var edit = GroupEditState(detail)
        let member = try #require(detail.members.first { $0.remove != nil })
        let person = PersonRow(userId: "new", title: "New Person", selectable: true)

        edit.values["location"] = "Park home"
        edit.values["name"] = detail.title
        edit.add([person])
        edit.remove(member.userId)

        #expect(edit.batch == .object([
            "fields": .object(["location": .string("Park home")]),
            "add": .array([.string("new")]),
            "remove": .array([.string(member.userId)]),
            "make_leader": .array([]),
            "remove_leader": .array([]),
        ]))
        #expect(edit.rows.last == .init(id: "new", title: "New Person", note: nil, isLeader: false, isPending: true, canRemove: true, canToggleLeader: false))
        #expect(!edit.rows.contains { $0.id == member.userId })
    }

    @Test func aLeaderCannotToggleLeadersOrRemoveRowsWithoutRemove() throws {
        let detail = try Self.leader()
        var edit = GroupEditState(detail)
        let own = try #require(detail.members.first { $0.remove == nil })

        edit.toggleLeader(own.userId)
        edit.remove(own.userId)

        #expect(edit.batch == Self.emptyBatch)
        #expect(edit.rows.allSatisfy { !$0.canToggleLeader })
    }

    @Test func staffToggleLeadersAndTogglingBackUnstages() throws {
        let detail = try Self.staff()
        var edit = GroupEditState(detail)
        let leader = try #require(detail.members.first { $0.isLeader })
        let member = try #require(detail.members.first { !$0.isLeader })

        edit.toggleLeader(member.userId)
        edit.toggleLeader(leader.userId)
        #expect(edit.batch.objectValue["make_leader"] == .array([.string(member.userId)]))
        #expect(edit.batch.objectValue["remove_leader"] == .array([.string(leader.userId)]))

        edit.toggleLeader(member.userId)
        #expect(edit.batch.objectValue["make_leader"] == .array([]))
    }

    @Test func addingSkipsMembersAndPeopleAlreadyAddedAndRemovingAPendingRowDropsIt() throws {
        let detail = try Self.leader()
        var edit = GroupEditState(detail)
        let member = try #require(detail.members.first)
        let person = PersonRow(userId: "new", title: "New Person", selectable: true)

        edit.add([PersonRow(userId: member.userId, title: member.title, selectable: true), person])
        edit.add([person])
        #expect(edit.batch.objectValue["add"] == .array([.string("new")]))

        edit.remove("new")
        #expect(edit.batch == Self.emptyBatch)
    }

    @Test func aFailedSaveKeepsTheChangesAndShowsEachProblemInPlace() throws {
        var edit = GroupEditState(try Self.leader())
        edit.values["name"] = ""
        let failed = try JSONDecoder().decode(SaveResult.self, from: TestMockResponses.data("save_group_changes.failed.json"))

        edit.show(failed)

        #expect(edit.fieldErrors == ["name": "Enter a name."])
        #expect(edit.rowErrors.values.contains("Already a member"))
        #expect(edit.values["name"] == "", "the staged change is kept")
    }

    // AC3: Done sends exactly the staged batch in one save.

    @Test func submittingAddsTheBatchAndAppliesOnSuccessOnlyWhenItSucceeded() async throws {
        let backend = StubBackendService(environment: .init(name: "Stub", backend: nil))
        let cache = ScreenCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        var registry = ScreenRegistry()
        registry.register("test.screen", data: [String: String].self) { _ in EmptyView() }
        let tab = TabCoordinator(
            item: TabItem(id: "t", title: "T", iconKey: "tab.t", screen: ScreenEnvelope(key: "test.screen", data: .object([:]))),
            context: ScreenContext(backend: backend, registry: registry, cache: cache, locale: { "en" })
        )
        let save = try #require(try Self.leader().save)
        let failed = try JSONDecoder().decode(JSONValue.self, from: TestMockResponses.data("save_group_changes.failed.json"))
        backend.enqueueCall(.success(failed), .success(.object(["ok": .bool(true)])))

        let first = await tab.submit(save, adding: ["p_batch": Self.emptyBatch], from: tab.root) { $0.objectValue["ok"] == .bool(true) }
        #expect(first == failed)
        #expect(backend.screenCalls.isEmpty, "a failed save refreshes nothing")

        _ = await tab.submit(save, adding: ["p_batch": Self.emptyBatch], from: tab.root) { $0.objectValue["ok"] == .bool(true) }
        #expect(backend.calls.last == .init(
            function: "save_group_changes",
            params: save.params.objectValue.merging(["p_batch": Self.emptyBatch]) { $1 },
            locale: "en"
        ))
        #expect(backend.screenCalls.count == 1, "an ok save refreshes the screen")
    }
}
