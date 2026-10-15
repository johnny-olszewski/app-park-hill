import Foundation
import Testing
@testable import ParkHill

@MainActor
struct CurrentScreenTrackerTests {
    private let below = ScreenEnvelope(key: "below", data: .object([:]))
    private let above = ScreenEnvelope(key: "above", data: .object([:]))

    @Test func hasNoCurrentScreenBeforeAnyAppears() {
        #expect(CurrentScreenTracker().current == nil)
    }

    @Test func theNewestScreenIsCurrent() {
        let tracker = CurrentScreenTracker()
        tracker.screenDidAppear(below, id: UUID())
        tracker.screenDidAppear(above, id: UUID())
        #expect(tracker.current == above)
    }

    @Test func leavingTheTopScreenMakesTheOneBelowCurrent() {
        let tracker = CurrentScreenTracker()
        let aboveID = UUID()
        tracker.screenDidAppear(below, id: UUID())
        tracker.screenDidAppear(above, id: aboveID)
        tracker.screenDidDisappear(id: aboveID)
        #expect(tracker.current == below)
    }

    @Test func aScreenAppearingAgainBecomesCurrent() {
        let tracker = CurrentScreenTracker()
        let belowID = UUID()
        tracker.screenDidAppear(below, id: belowID)
        tracker.screenDidAppear(above, id: UUID())
        tracker.screenDidAppear(below, id: belowID)
        #expect(tracker.current == below)
    }
}
