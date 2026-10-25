import Foundation
import Testing
@testable import ParkHill

/// Browse all groups: search and the recorded rows (IOS-025 AC4).
@MainActor
struct CommunityBrowseTests {
    private func row(_ title: String) -> GroupRow {
        GroupRow(groupId: title, title: title, subtitle: "", action: .unknown(type: nil))
    }

    @Test func searchFiltersByTitleIgnoringCaseAndSpaces() {
        let rows = [row("Mission Hills Group"), row("Point Loma Group"), row("Young Families")]
        #expect(CommunityBrowseScreen.filter(rows, by: " hill ").map(\.title) == ["Mission Hills Group"])
        #expect(CommunityBrowseScreen.filter(rows, by: "GROUP").count == 2)
        #expect(CommunityBrowseScreen.filter(rows, by: "").count == 3)
        #expect(CommunityBrowseScreen.filter(rows, by: "nothing").isEmpty)
    }

    @Test func staffBrowseRecordsEveryGroupWithTheLeaderlessOneFlagged() throws {
        let envelope = try JSONDecoder().decode(ScreenEnvelope.self, from: TestMockResponses.data("staff/get_screen.community.browse.json"))
        let data = try JSONDecoder().decode(CommunityBrowseData.self, from: JSONEncoder().encode(envelope.data))
        #expect(data.rows.count == 4)
        #expect(data.rows.filter { $0.badgeTone == .attention }.map(\.title) == ["Point Loma Group"])
    }
}
