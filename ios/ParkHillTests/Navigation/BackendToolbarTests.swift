import Foundation
import Testing
@testable import ParkHill

/// Toolbar items from the envelope (IOS-025 AC1).
@MainActor
struct BackendToolbarTests {
    private func item(_ id: String, _ action: Action) -> ToolbarItem {
        ToolbarItem(id: id, label: id, iconKey: "toolbar.\(id)", action: action)
    }

    private let navigate = Action.navigate(NavigateAction(
        type: .navigate, screenKey: "community.browse", params: .object([:]), presentation: .fullScreenCover
    ))

    @Test func itemsKeepBackendOrderAndDropUnknownActions() {
        let items = [item("b", navigate), item("x", .unknown(type: "teleport")), item("a", navigate)]
        #expect(BackendToolbar.shown(items, actions: ScreenActions()).map(\.id) == ["b", "a"])
    }

    @Test func noItemsShowNone() {
        #expect(BackendToolbar.shown([], actions: ScreenActions()).isEmpty)
    }

    @Test func staffHomeRecordsTheBrowseItem() throws {
        let envelope = try JSONDecoder().decode(ScreenEnvelope.self, from: TestMockResponses.data("staff/get_screen.community.home.json"))
        #expect(envelope.toolbar?.map(\.id) == ["browse_all_groups"])
        let memberHome = try JSONDecoder().decode(ScreenEnvelope.self, from: TestMockResponses.data("member_one/get_screen.community.home.json"))
        #expect(memberHome.toolbar == nil)
    }
}
