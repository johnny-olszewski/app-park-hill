import SwiftUI
import Testing
import UIKit
@testable import ParkHill

@MainActor
struct ScreenRegistryTests {
    private func makeRegistry() -> ScreenRegistry {
        var registry = ScreenRegistry()
        registry.registerSharedScreens(auth: StubAuthService())
        return registry
    }

    @Test func sharedScreensIncludeSignIn() {
        #expect(makeRegistry().isRegistered("auth.sign_in"))
    }

    @Test func resolvesARegisteredKey() throws {
        let screen = try #require(makeRegistry().resolve(.signIn()))
        #expect(screen.key == "auth.sign_in")
    }

    @Test func dropsAnUnregisteredKey() {
        #expect(makeRegistry().resolve(ScreenEnvelope(key: "future.screen", data: .object([:]))) == nil)
    }

    @Test func dropsDataThatDoesNotMatchTheModel() {
        #expect(makeRegistry().resolve(ScreenEnvelope(key: "auth.sign_in", data: .object(["title": .number(1)]))) == nil)
    }

    @Test func passesDecodedDataToTheScreen() throws {
        struct Data: Decodable, Equatable { let title: String }
        var registry = ScreenRegistry()
        var received: Data?
        registry.register("test.screen", data: Data.self) { data in
            received = data
            return EmptyView()
        }
        _ = try #require(registry.resolve(ScreenEnvelope(key: "test.screen", data: .object(["title": .string("Hello"), "extra": .bool(true)]))))
        #expect(received == Data(title: "Hello"))
    }

    @Test func realSignInFixtureResolves() throws {
        let envelope = try JSONDecoder().decode(ScreenEnvelope.self, from: TestFixtures.data("get_entry.json"))
        #expect(makeRegistry().resolve(envelope) != nil)
    }

    @Test func keepsTheEnvelopeItWasBuiltFrom() throws {
        let envelope = ScreenEnvelope.signIn()
        let screen = try #require(makeRegistry().resolve(envelope))
        #expect(screen.envelope == envelope)
    }

    @Test func reportsAResolvedScreenAppearingAndDisappearing() async throws {
        let tracker = RecordingScreenTracker()
        var registry = ScreenRegistry(tracker: tracker)
        registry.register("test.screen", data: JSONValue.self) { _ in Text("Test") }
        let envelope = ScreenEnvelope(key: "test.screen", data: .object([:]))
        let screen = try #require(registry.resolve(envelope))

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = UIHostingController(rootView: screen.view)
        window.isHidden = false
        try await waitUntil { !tracker.appeared.isEmpty }
        #expect(tracker.appeared.map(\.key) == ["test.screen"])

        window.rootViewController = UIHostingController(rootView: EmptyView())
        try await waitUntil { !tracker.disappeared.isEmpty }
        #expect(tracker.disappeared == tracker.appeared.map(\.id))
    }
}

@MainActor
private final class RecordingScreenTracker: ScreenTracker {
    private(set) var appeared: [(key: String, id: UUID)] = []
    private(set) var disappeared: [UUID] = []

    func screenDidAppear(_ envelope: ScreenEnvelope, id: UUID) {
        appeared.append((envelope.key, id))
    }

    func screenDidDisappear(id: UUID) {
        disappeared.append(id)
    }
}

/// Polls until `condition` holds, failing after about two seconds.
@MainActor
private func waitUntil(_ condition: () -> Bool) async throws {
    for _ in 0..<200 where !condition() {
        try await Task.sleep(for: .milliseconds(10))
    }
    #expect(condition(), "timed out")
}
