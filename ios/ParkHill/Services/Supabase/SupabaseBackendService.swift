import Foundation
import Supabase

/// Production `BackendService`: calls the backend's RPC functions through the
/// shared Supabase client.
struct SupabaseBackendService: BackendService {
    private let client: SupabaseClient

    init(environment: AppEnvironment) {
        self.init(client: SupabaseClientProvider.client(for: environment))
    }

    init(client: SupabaseClient) {
        self.client = client
    }

    func getEntry(locale: String) async throws(BackendError) -> ScreenEnvelope {
        try await call(.getEntry, params: EntryParams(p_locale: locale))
    }

    func getScreen(key: String, locale: String, params: [String: JSONValue]) async throws(BackendError) -> ScreenEnvelope {
        try await call(.getScreen, params: ScreenParams(p_key: key, p_locale: locale, p_params: params))
    }

    func getTabs(locale: String) async throws(BackendError) -> TabsResponse {
        try await call(.getTabs, params: EntryParams(p_locale: locale))
    }

    func whoami() async throws(BackendError) -> Profile {
        try await call(.whoami, params: NoParams())
    }

    func call(function: String, params: [String: JSONValue], locale: String) async throws(BackendError) {
        var params = params
        params["p_locale"] = .string(locale)
        do {
            _ = try await client.rpc(function, params: params).execute()
        } catch {
            throw Self.map(error)
        }
    }

    private func call<Response: Decodable>(
        _ function: RPCFunction,
        params: some Encodable & Sendable
    ) async throws(BackendError) -> Response {
        let data: Data
        do {
            data = try await client.rpc(function.rawValue, params: params).execute().data
        } catch {
            throw Self.map(error)
        }
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw .decoding
        }
    }

    /// Maps SDK and transport errors to `BackendError`. Error identity comes
    /// from the PostgREST `message` (contract/README.md, Errors).
    static func map(_ error: any Error) -> BackendError {
        switch error {
        case let error as PostgrestError:
            if error.message == "unknown_screen" { return .unknownScreen }
            if error.message == "session_ended" { return .unauthorized }
            if error.message == "screen_unavailable" { return .screenUnavailable(message: error.detail ?? "") }
            if error.message == "action_refused" { return .actionRefused(message: error.detail ?? "") }
            // PGRST30x: missing, invalid or expired JWT.
            if let code = error.code, code.hasPrefix("PGRST30") { return .unauthorized }
            return .server
        case let error as HTTPError:
            return error.response.statusCode == 401 ? .unauthorized : .server
        case is URLError, is CancellationError:
            return .network
        case is DecodingError:
            return .decoding
        default:
            return .server
        }
    }
}

private struct NoParams: Encodable, Sendable {}

private struct EntryParams: Encodable, Sendable {
    let p_locale: String
}

private struct ScreenParams: Encodable, Sendable {
    let p_key: String
    let p_locale: String
    let p_params: [String: JSONValue]
}
