import Foundation

/// Mock `BackendService`: answers from contract fixtures and makes no network
/// calls. The entry is the persona picker (`auth.sign_in.mock`); `get_screen`
/// reads `get_screen.<key>.json`; `whoami` reads the signed-in persona's
/// `whoami.json`.
struct MockBackendService: BackendService {
    private let fixtures: FixtureStore
    private let personaState: MockPersonaState
    private let entry: ScreenEnvelope?

    init(environment: AppEnvironment) {
        self.init(
            fixtures: .bundled,
            personaState: .shared,
            entry: try? PersonaPickerData.fromDataset(at: PersonaPickerData.bundledDatasetURL).envelope
        )
    }

    /// With no `entry`, `getEntry` reads `get_entry.json`.
    init(fixtures: FixtureStore, personaState: MockPersonaState, entry: ScreenEnvelope? = nil) {
        self.fixtures = fixtures
        self.personaState = personaState
        self.entry = entry
    }

    func getEntry(locale: String) async throws(BackendError) -> ScreenEnvelope {
        if let entry { return entry }
        return try decode("get_entry", missing: .server)
    }

    func getScreen(key: String, locale: String, params: [String: JSONValue]) async throws(BackendError) -> ScreenEnvelope {
        if let entry, key == entry.key { return entry }
        return try decode("get_screen.\(key)", missing: .unknownScreen)
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
