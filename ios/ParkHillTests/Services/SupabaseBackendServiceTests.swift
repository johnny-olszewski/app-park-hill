import Foundation
import Testing
@testable import ParkHill

/// SupabaseBackendService against a stubbed transport: no backend needed, so
/// these run in Mock CI as well as Dev.
@Suite(.serialized)
struct SupabaseBackendServiceTests {
    private static let environment = AppEnvironment(
        name: "Dev",
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
        let fixture = try String(decoding: TestFixtures.data("get_entry.json"), as: UTF8.self)
        StubURLProtocol.stub(.http(status: 200, body: fixture))

        let envelope = try await makeService().getEntry(locale: "en")

        let request = try #require(StubURLProtocol.requests.last)
        #expect(request.url?.path == "/rest/v1/rpc/get_entry")
        #expect(request.value(forHTTPHeaderField: "X-App-Config") == "dev")
        #expect(request.value(forHTTPHeaderField: "X-App-Platform") == "ios")
        let version = try #require(request.value(forHTTPHeaderField: "X-App-Version"))
        #expect(version.wholeMatch(of: /\d+\.\d+\.\d+ \(\d+\)/) != nil)
        #expect(request.value(forHTTPHeaderField: "Accept-Language") == (Locale.preferredLanguages.first ?? "en"))
        #expect(request.value(forHTTPHeaderField: "apikey") == "test-anon-key")
        #expect(try body(of: request) == ["p_locale": .string("en")])
        #expect(envelope == (try JSONDecoder().decode(ScreenEnvelope.self, from: TestFixtures.data("get_entry.json"))))
    }

    @Test func getScreenSendsKeyLocaleAndParams() async throws {
        let fixture = try String(decoding: TestFixtures.data("get_screen.auth.sign_in.json"), as: UTF8.self)
        StubURLProtocol.stub(.http(status: 200, body: fixture))

        _ = try await makeService().getScreen(key: "auth.sign_in", locale: "es", params: ["id": .string("7")])

        let request = try #require(StubURLProtocol.requests.last)
        #expect(request.url?.path == "/rest/v1/rpc/get_screen")
        #expect(try body(of: request) == [
            "p_key": .string("auth.sign_in"),
            "p_locale": .string("es"),
            "p_params": .object(["id": .string("7")]),
        ])
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
