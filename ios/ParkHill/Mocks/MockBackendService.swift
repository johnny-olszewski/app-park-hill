import Foundation

/// Mock `BackendService`: answers from contract fixtures and makes no network
/// calls. `get_entry` reads `get_entry.json`; `get_screen` reads
/// `get_screen.<key>.json`.
struct MockBackendService: BackendService {
    private let fixtures: FixtureStore
    private let personaState: MockPersonaState

    init(environment: AppEnvironment) {
        self.init(fixtures: .bundled, personaState: MockPersonaState())
    }

    init(fixtures: FixtureStore, personaState: MockPersonaState) {
        self.fixtures = fixtures
        self.personaState = personaState
    }

    func getEntry(locale: String) async throws(BackendError) -> ScreenEnvelope {
        try envelope(named: "get_entry", missing: .server)
    }

    func getScreen(key: String, locale: String, params: [String: JSONValue]) async throws(BackendError) -> ScreenEnvelope {
        try envelope(named: "get_screen.\(key)", missing: .unknownScreen)
    }

    private func envelope(named name: String, missing: BackendError) throws(BackendError) -> ScreenEnvelope {
        guard let data = fixtures.data(named: name, persona: personaState.current) else {
            throw missing
        }
        do {
            return try JSONDecoder().decode(ScreenEnvelope.self, from: data)
        } catch {
            throw .decoding
        }
    }
}
