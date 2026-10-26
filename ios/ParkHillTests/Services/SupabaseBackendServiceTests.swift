import Foundation
import Testing
@testable import ParkHill

/// SupabaseBackendService against a stubbed transport: no backend needed, so
/// these run in Mock CI as well as Local.
@Suite(.serialized)
struct SupabaseBackendServiceTests {
    private static let environment = AppEnvironment(
        name: "Local",
        backend: BackendTarget(url: URL(string: "http://backend.test")!, anonKey: "test-anon-key")
    )

    private func makeService() -> SupabaseBackendService {
        let client = SupabaseClientProvider.makeClient(
            environment: Self.environment,
            session: StubURLProtocol.makeSession()
        )
        return SupabaseBackendService(client: client)
    }

    // MARK: Requests

    @Test func getEntryCallsTheRPCWithStandardHeaders() async throws {
        let mockResponse = try String(decoding: TestMockResponses.data("get_entry.json"), as: UTF8.self)
        StubURLProtocol.stub(.http(status: 200, body: mockResponse))

        let envelope = try await makeService().getEntry(locale: "en")

        let request = try #require(StubURLProtocol.requests.last)
        #expect(request.url?.path == "/rest/v1/rpc/get_entry")
        #expect(request.value(forHTTPHeaderField: "X-App-Config") == "local")
        #expect(request.value(forHTTPHeaderField: "X-App-Platform") == "ios")
        let version = try #require(request.value(forHTTPHeaderField: "X-App-Version"))
        #expect(version.wholeMatch(of: /\d+\.\d+\.\d+ \(\d+\)/) != nil)
        #expect(request.value(forHTTPHeaderField: "Accept-Language") == (Locale.preferredLanguages.first ?? "en"))
        #expect(request.value(forHTTPHeaderField: "apikey") == "test-anon-key")
        #expect(try body(of: request) == ["p_locale": .string("en")])
        #expect(envelope == (try JSONDecoder().decode(ScreenEnvelope.self, from: TestMockResponses.data("get_entry.json"))))
    }

    @Test func getScreenSendsKeyLocaleAndParams() async throws {
        let mockResponse = try String(decoding: TestMockResponses.data("get_screen.auth.sign_in.json"), as: UTF8.self)
        StubURLProtocol.stub(.http(status: 200, body: mockResponse))

        _ = try await makeService().getScreen(key: "auth.sign_in", locale: "es", params: ["id": .string("7")])

        let request = try #require(StubURLProtocol.requests.last)
        #expect(request.url?.path == "/rest/v1/rpc/get_screen")
        #expect(try body(of: request) == [
            "p_key": .string("auth.sign_in"),
            "p_locale": .string("es"),
            "p_params": .object(["id": .string("7")]),
        ])
    }

    @Test func getTabsSendsTheLocaleAndDecodesTheTabs() async throws {
        let mockResponse = try String(decoding: TestMockResponses.data("attendee/get_tabs.json"), as: UTF8.self)
        StubURLProtocol.stub(.http(status: 200, body: mockResponse))

        let response = try await makeService().getTabs(locale: "en")

        let request = try #require(StubURLProtocol.requests.last)
        #expect(request.url?.path == "/rest/v1/rpc/get_tabs")
        #expect(try body(of: request) == ["p_locale": .string("en")])
        #expect(response.tabs.map(\.id) == ["home", "community"])
        #expect(response.tabs.first?.iconKey == "tab.home")
    }

    @Test func callSendsTheActionsParamsWithTheLocale() async throws {
        StubURLProtocol.stub(.http(status: 200, body: "{}"))

        try await makeService().call(function: "leave_group", params: ["p_group_id": .string("g")], locale: "es")

        let request = try #require(StubURLProtocol.requests.last)
        #expect(request.url?.path == "/rest/v1/rpc/leave_group")
        #expect(try body(of: request) == ["p_group_id": .string("g"), "p_locale": .string("es")])
    }

    @Test func aRefusedCallCarriesTheBackendsMessage() async {
        StubURLProtocol.stub(.http(status: 400, body: #"{"code":"P0001","message":"action_refused","details":"Not any more.","hint":null}"#))
        await #expect(throws: BackendError.actionRefused(message: "Not any more.")) {
            try await makeService().call(function: "remove_member", params: [:], locale: "en")
        }
    }

    @Test func standardHeadersFallBackToEnglish() {
        #expect(StandardHeaders.make(environment: Self.environment, preferredLanguages: ["fr-CA", "en"])["Accept-Language"] == "fr-CA")
        #expect(StandardHeaders.make(environment: Self.environment, preferredLanguages: [])["Accept-Language"] == "en")
    }

    @Test func theSharedClientIsCreatedOnce() {
        let first = SupabaseClientProvider.client(for: Self.environment)
        let second = SupabaseClientProvider.client(for: Self.environment)
        #expect(first === second)
    }

    // MARK: Errors

    @Test(arguments: [
        (StubURLProtocol.Response.http(status: 400, body: #"{"code":"P0001","message":"unknown_screen","details":"x","hint":null}"#), BackendError.unknownScreen),
        (.http(status: 400, body: #"{"code":"P0001","message":"session_ended","details":null,"hint":null}"#), .unauthorized),
        (.http(status: 400, body: #"{"code":"P0001","message":"screen_unavailable","details":"You're no longer in this group.","hint":null}"#), .screenUnavailable(message: "You're no longer in this group.")),
        (.http(status: 400, body: #"{"code":"P0001","message":"action_refused","details":"You can't make this change anymore.","hint":null}"#), .actionRefused(message: "You can't make this change anymore.")),
        (.http(status: 401, body: #"{"code":"PGRST301","message":"JWT expired","details":null,"hint":null}"#), .unauthorized),
        (.http(status: 401, body: "Unauthorized"), .unauthorized),
        (.http(status: 500, body: #"{"code":"XX000","message":"boom","details":null,"hint":null}"#), .server),
        (.http(status: 502, body: "Bad gateway"), .server),
        (.http(status: 200, body: #"{"unexpected": true}"#), .decoding),
        (.failure(.notConnectedToInternet), .network),
        (.failure(.timedOut), .network),
    ])
    func errorsMapToBackendError(response: StubURLProtocol.Response, expected: BackendError) async {
        StubURLProtocol.stub(response)
        await #expect(throws: expected) {
            _ = try await makeService().getEntry(locale: "en")
        }
    }

    private func body(of request: URLRequest) throws -> [String: JSONValue] {
        try JSONDecoder().decode([String: JSONValue].self, from: #require(request.bodyData))
    }
}
