import SwiftUI
import Testing
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
}
