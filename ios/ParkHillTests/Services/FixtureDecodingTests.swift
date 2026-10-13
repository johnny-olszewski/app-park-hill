import Foundation
import Testing
@testable import ParkHill

struct FixtureDecodingTests {
    @Test func fixturesArePresent() {
        #expect(TestFixtures.allJSONPaths().contains("get_entry.json"))
    }

    @Test(arguments: TestFixtures.screenEnvelopePaths())
    func everyScreenFixtureDecodesAsAScreenEnvelope(path: String) throws {
        let envelope = try JSONDecoder().decode(ScreenEnvelope.self, from: TestFixtures.data(path))
        #expect(!envelope.key.isEmpty)
        guard case .object = envelope.data else {
            Issue.record("\(path): data is not an object")
            return
        }
    }

    @Test func entryFixtureIsTheSignInScreen() throws {
        let envelope = try JSONDecoder().decode(ScreenEnvelope.self, from: TestFixtures.data("get_entry.json"))
        #expect(envelope.key == "auth.sign_in")
        guard case .object(let data) = envelope.data else {
            Issue.record("data is not an object")
            return
        }
        #expect(data["title"] == .string("Sign in"))
        #expect(data["secondary_actions"] == .array([]))
    }

    @Test func unknownFieldsAreIgnored() throws {
        let json = #"{"key": "auth.sign_in", "data": {"title": "Sign in"}, "toolbar": [], "future_field": {"x": 1}}"#
        let envelope = try JSONDecoder().decode(ScreenEnvelope.self, from: Data(json.utf8))
        #expect(envelope == ScreenEnvelope(key: "auth.sign_in", data: .object(["title": .string("Sign in")])))
    }

    @Test func jsonValueRoundTrips() throws {
        let value: JSONValue = .object([
            "s": .string("a"), "n": .number(1.5), "b": .bool(true),
            "z": .null, "a": .array([.number(1), .string("x")]),
        ])
        let decoded = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
        #expect(decoded == value)
    }
}
