import os

/// The persona the Mock build is signed in as, shared by the mock services.
/// Set by the mock auth service (IOS-005); nil means signed out.
final class MockPersonaState: Sendable {
    private let persona = OSAllocatedUnfairLock<String?>(initialState: nil)

    var current: String? {
        get { persona.withLock { $0 } }
        set { persona.withLock { $0 = newValue } }
    }
}
