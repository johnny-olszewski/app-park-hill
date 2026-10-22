import Foundation

/// Mock `BackendService`: answers from contract fixtures and makes no network
/// calls. The entry is the recorded `get_entry.json` (the production
/// `auth.sign_in`); `get_screen` reads `get_screen.<key>.json`; `get_tabs` and
/// `whoami` read the signed-in persona's `get_tabs.json` and `whoami.json`.
struct MockBackendService: BackendService {
    private let fixtures: FixtureStore
    private let personaState: MockPersonaState

    init(environment: AppEnvironment) {
        self.init(fixtures: .bundled, personaState: .shared)
    }

    init(fixtures: FixtureStore, personaState: MockPersonaState) {
        self.fixtures = fixtures
        self.personaState = personaState
    }

    func getEntry(locale: String) async throws(BackendError) -> ScreenEnvelope {
        try decode("get_entry", missing: .server)
    }

    func getScreen(key: String, locale: String, params: [String: JSONValue]) async throws(BackendError) -> ScreenEnvelope {
        return try decode("get_screen.\(key)", missing: .unknownScreen)
    }

    func getTabs(locale: String) async throws(BackendError) -> TabsResponse {
        guard personaState.current != nil else { throw .unauthorized }
        return try decode("get_tabs", missing: .server)
    }

    func whoami() async throws(BackendError) -> Profile {
        guard personaState.current != nil else { throw .unauthorized }
        return try decode("whoami", missing: .server)
    }

    private func decode<Response: Decodable>(_ name: String, missing: BackendError) throws(BackendError) -> Response {
        guard let data = fixtures.data(named: name, persona: personaState.current) else {
            throw missing
        }
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw .decoding
        }
    }
}
