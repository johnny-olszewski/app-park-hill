/// The only path to backend data (guide 5.1). Each configuration's binding
/// declares the concrete type as `AppBackendService`.
protocol BackendService: Sendable {
    init(environment: AppEnvironment)

    /// The signed-out entry screen (`get_entry`).
    func getEntry(locale: String) async throws(BackendError) -> ScreenEnvelope

    /// One screen by key (`get_screen`).
    func getScreen(key: String, locale: String, params: [String: JSONValue]) async throws(BackendError) -> ScreenEnvelope
}

extension BackendService {
    func getScreen(key: String, locale: String) async throws(BackendError) -> ScreenEnvelope {
        try await getScreen(key: key, locale: locale, params: [:])
    }
}

/// Every failure a caller needs to tell apart. Callers never see SDK errors.
enum BackendError: Error, Equatable, Sendable {
    /// No response arrived: offline, timed out, cancelled.
    case network
    /// The backend does not register the requested screen key.
    case unknownScreen
    /// The session is missing, expired, invalid or ended (`session_ended`).
    case unauthorized
    /// A response arrived but did not match the contract.
    case decoding
    /// Any other refusal or failure reported by the backend.
    case server
}
