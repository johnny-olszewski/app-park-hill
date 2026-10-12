import Foundation
import os
@testable import ParkHill

/// Test double for `BackendService`: answers `getEntry` with queued results and
/// counts calls.
final class StubBackendService: BackendService {
    private struct State {
        var entryResults: [Result<ScreenEnvelope, BackendError>] = []
        var entryCalls: [String] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    init(environment: AppEnvironment) {}

    convenience init(entry results: Result<ScreenEnvelope, BackendError>...) {
        self.init(environment: .init(name: "Stub", backend: nil))
        enqueueEntry(results)
    }

    /// Results for the next `getEntry` calls, in order. The last one repeats.
    func enqueueEntry(_ results: [Result<ScreenEnvelope, BackendError>]) {
        state.withLock { $0.entryResults.append(contentsOf: results) }
    }

    /// Locales passed to `getEntry`, one per call.
    var entryCalls: [String] {
        state.withLock { $0.entryCalls }
    }

    func getEntry(locale: String) async throws(BackendError) -> ScreenEnvelope {
        let result = state.withLock { state in
            state.entryCalls.append(locale)
            return state.entryResults.count > 1 ? state.entryResults.removeFirst() : state.entryResults.first
        }
        guard let result else { throw .server }
        return try result.get()
    }

    func getScreen(key: String, locale: String, params: [String: JSONValue]) async throws(BackendError) -> ScreenEnvelope {
        throw .unknownScreen
    }
}

extension ScreenEnvelope {
    static func signIn(title: String = "Sign in") -> ScreenEnvelope {
        ScreenEnvelope(key: "auth.sign_in", data: .object(["title": .string(title)]))
    }
}
