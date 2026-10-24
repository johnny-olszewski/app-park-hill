import Foundation
import Testing
@testable import ParkHill

struct MockResponseDecodingTests {
    @Test func mockResponsesArePresent() {
        #expect(TestMockResponses.allJSONPaths().contains("get_entry.json"))
    }

    @Test(arguments: TestMockResponses.allJSONPaths())
    func everyMockResponseDecodesWithItsTypeFromResponsesJSON(path: String) throws {
        let name = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        let type = try #require(try TestMockResponses.responseTypes()[name], "\(path) has no type in contract/responses.json")
        let decode = try #require(Self.decoders[type], "\(type) has no decoder in this test")
        try decode(TestMockResponses.data(path))
    }

    /// Every type `contract/responses.json` names, by name.
    private static let decoders: [String: @Sendable (Data) throws -> Void] = [
        "ScreenEnvelope": { _ = try JSONDecoder().decode(ScreenEnvelope.self, from: $0) },
        "TabsResponse": { _ = try JSONDecoder().decode(TabsResponse.self, from: $0) },
        "Profile": { _ = try JSONDecoder().decode(Profile.self, from: $0) },
        "SignInSuccess": { _ = try JSONDecoder().decode(SignInSuccess.self, from: $0) },
        "SignInFailure": { _ = try JSONDecoder().decode(SignInFailure.self, from: $0) },
    ]

    @Test(arguments: TestMockResponses.screenEnvelopePaths())
    func everyScreenMockResponseDecodesAsAScreenEnvelope(path: String) throws {
        let envelope = try JSONDecoder().decode(ScreenEnvelope.self, from: TestMockResponses.data(path))
        #expect(!envelope.key.isEmpty)
        guard case .object = envelope.data else {
            Issue.record("\(path): data is not an object")
            return
        }
    }

    @Test func entryMockResponseIsTheSignInScreen() throws {
        let envelope = try JSONDecoder().decode(ScreenEnvelope.self, from: TestMockResponses.data("get_entry.json"))
        #expect(envelope.key == "auth.sign_in")
        guard case .object(let data) = envelope.data else {
            Issue.record("data is not an object")
            return
        }
        #expect(data["title"] == .string("Sign in"))
        #expect(data["secondary_actions"] == .array([]))
    }

    @Test func signInMockResponsesDecodeIntoTheirModels() throws {
        let ok = try JSONDecoder().decode(SignInSuccess.self, from: TestMockResponses.data("sign_in.ok.json"))
        #expect(ok.status == "ok")
        #expect(!ok.session.userId.isEmpty)
        let error = try JSONDecoder().decode(SignInFailure.self, from: TestMockResponses.data("sign_in.error.json"))
        #expect(error.status == "error")
        #expect(error.code == "invalid_credentials")
        #expect(!error.message.isEmpty)
    }

    @Test func whoamiMockResponsesDecodeIntoProfiles() throws {
        let paths = TestMockResponses.allJSONPaths().filter { $0.hasSuffix("/whoami.json") }
        #expect(!paths.isEmpty)
        for path in paths {
            let profile = try JSONDecoder().decode(Profile.self, from: TestMockResponses.data(path))
            #expect(!profile.id.isEmpty)
            #expect(!profile.displayName.isEmpty)
        }
    }

    @Test func tabsMockResponsesDecodeIntoTabs() throws {
        let paths = TestMockResponses.allJSONPaths().filter { $0.hasSuffix("/get_tabs.json") }
        #expect(!paths.isEmpty)
        for path in paths {
            let response = try JSONDecoder().decode(TabsResponse.self, from: TestMockResponses.data(path))
            #expect(!response.tabs.isEmpty)
            #expect(response.tabs.allSatisfy { !$0.title.isEmpty && !$0.iconKey.isEmpty })
        }
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
