import Foundation
import os
@testable import ParkHill

/// Test double for `BackendService`: answers `getEntry` and `getTabs` with
/// queued results and counts calls.
final class StubBackendService: BackendService {
    private struct State {
        var entryResults: [Result<ScreenEnvelope, BackendError>] = []
        var entryCalls: [String] = []
        var tabsResults: [Result<TabsResponse, BackendError>] = []
        var tabsCalls: [String] = []
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

    /// Results for the next `getTabs` calls, in order. The last one repeats.
    func enqueueTabs(_ results: Result<TabsResponse, BackendError>...) {
        state.withLock { $0.tabsResults.append(contentsOf: results) }
    }

    /// Locales passed to `getTabs`, one per call.
    var tabsCalls: [String] {
        state.withLock { $0.tabsCalls }
    }

    func getTabs(locale: String) async throws(BackendError) -> TabsResponse {
        let result = state.withLock { state in
            state.tabsCalls.append(locale)
            return state.tabsResults.count > 1 ? state.tabsResults.removeFirst() : state.tabsResults.first
        }
        guard let result else { throw .server }
        return try result.get()
    }

    private let whoamiCallCount = OSAllocatedUnfairLock(initialState: 0)

    /// Calls to `whoami`.
    var whoamiCalls: Int { whoamiCallCount.withLock { $0 } }

    func whoami() async throws(BackendError) -> Profile {
        whoamiCallCount.withLock { $0 += 1 }
        return Profile(id: "stub", displayName: "Stub")
    }
}

extension TabsResponse {
    /// Tabs with empty root screens, one per `(id, screen key)`, in order.
    static func tabs(_ tabs: (id: String, screen: String)...) -> TabsResponse {
        TabsResponse(tabs: tabs.map {
            TabItem(id: $0.id, title: $0.id.capitalized, iconKey: "tab.\($0.id)", screen: ScreenEnvelope(key: $0.screen, data: .object([:])))
        })
    }
}

extension ScreenEnvelope {
    /// A complete `auth.sign_in` envelope with the given title.
    static func signIn(title: String = "Sign in") -> ScreenEnvelope {
        ScreenEnvelope(key: "auth.sign_in", data: .object([
            "title": .string(title),
            "email_label": .string("Email"),
            "password_label": .string("Password"),
            "submit_label": .string("Sign in"),
            "cannot_connect_message": .string("Can't connect."),
            "session_ended_message": .string("You've been signed out."),
            "secondary_actions": .array([]),
        ]))
    }
}
