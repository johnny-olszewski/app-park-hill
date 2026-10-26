import Foundation

/// Mock `BackendService`: answers from mock responses and makes no network
/// calls. The entry is the recorded `get_entry.json` (the production
/// `auth.sign_in`); `get_screen` reads `get_screen.<key>@<params>.json`, else
/// `get_screen.<key>.json`; `get_tabs` and
/// `whoami` read the signed-in persona's `get_tabs.json` and `whoami.json`.
/// A `call` succeeds and changes nothing: mock responses are static (guide 6).
struct MockBackendService: BackendService {
    private let responses: MockResponseStore
    private let personaState: MockPersonaState

    init(environment: AppEnvironment) {
        self.init(responses: .bundled, personaState: .shared)
    }

    init(responses: MockResponseStore, personaState: MockPersonaState) {
        self.responses = responses
        self.personaState = personaState
    }

    func getEntry(locale: String) async throws(BackendError) -> ScreenEnvelope {
        try decode(RPCFunction.getEntry.rawValue, missing: .server)
    }

    func getScreen(key: String, locale: String, params: [String: JSONValue]) async throws(BackendError) -> ScreenEnvelope {
        let name = "\(RPCFunction.getScreen.rawValue).\(key)"
        return try decode([MockResponseStore.name(name, params: params), name], missing: .unknownScreen)
    }

    func getTabs(locale: String) async throws(BackendError) -> TabsResponse {
        guard personaState.current != nil else { throw .unauthorized }
        return try decode(RPCFunction.getTabs.rawValue, missing: .server)
    }

    func whoami() async throws(BackendError) -> Profile {
        guard personaState.current != nil else { throw .unauthorized }
        return try decode(RPCFunction.whoami.rawValue, missing: .server)
    }

    func call(function: String, params: [String: JSONValue], locale: String) async throws(BackendError) {
        guard personaState.current != nil else { throw .unauthorized }
    }

    private func decode<Response: Decodable>(_ name: String, missing: BackendError) throws(BackendError) -> Response {
        try decode([name], missing: missing)
    }

    /// Decodes the first of `names` that has a mock response.
    private func decode<Response: Decodable>(_ names: [String], missing: BackendError) throws(BackendError) -> Response {
        guard let data = names.lazy.compactMap({ responses.data(named: $0, persona: personaState.current) }).first else {
            throw missing
        }
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw .decoding
        }
    }
}
