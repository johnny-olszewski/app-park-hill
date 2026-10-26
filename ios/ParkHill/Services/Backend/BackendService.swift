/// The only path to backend data (guide 5.1). Each configuration's binding
/// declares the concrete type as `AppBackendService`.
protocol BackendService: Sendable {
    /// The signed-out entry screen (`get_entry`).
    func getEntry(locale: String) async throws(BackendError) -> ScreenEnvelope

    /// One screen by key (`get_screen`).
    func getScreen(key: String, locale: String, params: [String: JSONValue]) async throws(BackendError) -> ScreenEnvelope

    /// The signed-in app's tabs (`get_tabs`). Refused as `unauthorized` when
    /// there is no active session.
    func getTabs(locale: String) async throws(BackendError) -> TabsResponse

    /// The signed-in caller's profile (`whoami`). Refused as `unauthorized`
    /// when there is no active session.
    func whoami() async throws(BackendError) -> Profile

    /// A `call` action's backend function, with the action's `params` and
    /// `p_locale` added. Returns the response body, which most callers
    /// ignore; edit mode's save decodes it as a `SaveResult`.
    @discardableResult
    func call(function: String, params: [String: JSONValue], locale: String) async throws(BackendError) -> JSONValue
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
    /// The caller may no longer see the screen (`screen_unavailable`), with
    /// the backend's message (guide 5.3 rule 9).
    case screenUnavailable(message: String)
    /// The caller may no longer make the call (`action_refused`), with the
    /// backend's message.
    case actionRefused(message: String)
    /// Any other refusal or failure reported by the backend.
    case server
}
