import Foundation
import SwiftUI
import Testing
@testable import ParkHill

/// The people picker and sheets (IOS-012 AC2 to AC4), with `leader`'s
/// recorded picker for their group.
@MainActor
struct PeoplePickerTests {
    private let cache = ScreenCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
    private let backend = StubBackendService(environment: .init(name: "Stub", backend: nil))

    private static func picker() throws -> PeoplePickerData {
        let envelope = try JSONDecoder().decode(
            ScreenEnvelope.self,
            from: TestMockResponses.data("leader/get_screen.people.picker@group_id=d44d5b87-37ce-5db5-9e33-43f477b42f1e.json")
        )
        return try JSONDecoder().decode(PeoplePickerData.self, from: JSONEncoder().encode(envelope.data))
    }

    // AC2: the backend decides who can be chosen.

    @Test func rowsThatAreNotSelectableCannotBeChosen() throws {
        var state = PeoplePickerState(rows: try Self.picker().rows)
        let member = try #require(state.rows.first { !$0.selectable })
        #expect(member.note == "Already a member")

        state.toggle(member)

        #expect(!state.isChosen(member))
        #expect(state.chosenRows.isEmpty)
    }

    @Test func choosingTwiceUnchooses() throws {
        var state = PeoplePickerState(rows: try Self.picker().rows)
        let person = try #require(state.rows.first { $0.selectable })
        state.toggle(person)
        #expect(state.chosenRows == [person])
        state.toggle(person)
        #expect(state.chosenRows.isEmpty)
    }

    // AC4: search filters by name and keeps chosen people chosen.

    @Test func searchFiltersByNameAndKeepsTheChosen() throws {
        var state = PeoplePickerState(rows: try Self.picker().rows)
        let attendee = try #require(state.rows.first { $0.title == "Attendee" })
        state.toggle(attendee)

        state.query = " lopez "
        #expect(!state.visibleRows.isEmpty)
        #expect(state.visibleRows.allSatisfy { $0.title.localizedCaseInsensitiveContains("lopez") })
        #expect(state.chosenRows == [attendee], "chosen people stay chosen while hidden")

        state.query = ""
        #expect(state.visibleRows == state.rows)
    }

    // AC3: Add hands back every chosen person; Cancel and dragging down hand back nothing.

    private func tab() -> TabCoordinator {
        var registry = ScreenRegistry()
        registry.register(ScreenKey.peoplePicker, data: PeoplePickerData.self) { _ in EmptyView() }
        registry.register("test.screen", data: [String: String].self) { _ in EmptyView() }
        let context = ScreenContext(backend: backend, registry: registry, cache: cache, locale: { "en" })
        return TabCoordinator(
            item: TabItem(id: "t", title: "T", iconKey: "tab.t", screen: ScreenEnvelope(key: "test.screen", data: .object([:]))),
            context: context
        )
    }

    private static let openPicker = Action.navigate(NavigateAction(
        type: .navigate, screenKey: ScreenKey.peoplePicker, params: .object(["group_id": .string("g")]), presentation: .sheet
    ))

    @Test func aSheetOpensOverALoadingStateAndAddHandsBackTheChosen() async throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let tab = tab()
        var handed: [[PersonRow]] = []

        tab.actions.open(Self.openPicker) { handed.append($0) }
        let sheet = try #require(tab.presented?.screen)
        guard case .loading = sheet.state else { Issue.record("not loading first"); return }
        #expect(tab.path.isEmpty, "a sheet is not pushed")

        let chosen = try Self.picker().rows.filter(\.selectable).prefix(2)
        tab.returnPeople(Array(chosen))

        #expect(tab.presented == nil)
        #expect(handed == [Array(chosen)])
    }

    @Test func cancellingOrDraggingDownHandsBackNothing() throws {
        let tab = tab()
        var handed = 0
        tab.actions.open(Self.openPicker) { _ in handed += 1 }
        #expect(tab.presented != nil)

        tab.dismiss()

        #expect(tab.presented == nil)
        #expect(handed == 0)
    }

    @Test func aCoverPresentsItsSheetsThroughTheTab() throws {
        let tab = tab()
        tab.perform(.navigate(NavigateAction(type: .navigate, screenKey: "test.screen", params: .object([:]), presentation: .fullScreenCover)))
        let cover = try #require(tab.cover)
        var handed: [[PersonRow]] = []

        cover.actions.open(Self.openPicker) { handed.append($0) }
        #expect(tab.presented != nil)
        tab.returnPeople([])

        #expect(handed == [[]])
        #expect(tab.cover != nil, "the cover stays open")
    }
}
