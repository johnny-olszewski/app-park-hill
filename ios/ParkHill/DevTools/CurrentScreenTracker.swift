import Foundation
import Observation

/// The backend-driven screens currently on screen, newest last. The newest is
/// the current screen: a cover or a pushed screen appears after the one below
/// it, and leaving it makes the one below current again.
@MainActor
@Observable
final class CurrentScreenTracker: ScreenTracker {
    private struct Visible {
        let id: UUID
        let envelope: ScreenEnvelope
    }

    private var visible: [Visible] = []

    /// The screen on top, or nil before any backend-driven screen appears.
    var current: ScreenEnvelope? {
        visible.last?.envelope
    }

    func screenDidAppear(_ envelope: ScreenEnvelope, id: UUID) {
        visible.removeAll { $0.id == id }
        visible.append(Visible(id: id, envelope: envelope))
    }

    func screenDidDisappear(id: UUID) {
        visible.removeAll { $0.id == id }
    }
}
