import Foundation

/// Told when a backend-driven screen appears and disappears, so debug tooling
/// can show what the current screen received. `ScreenRegistry` reports every
/// screen it resolves; screens never call this. Release builds supply none.
@MainActor
protocol ScreenTracker: AnyObject {
    /// `id` identifies one resolved screen, so the same key shown twice (for
    /// example pushed over itself) is tracked as two screens.
    func screenDidAppear(_ envelope: ScreenEnvelope, id: UUID)
    func screenDidDisappear(id: UUID)
}
