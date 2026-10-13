/// Wraps a `BackendService` with the unauthorized rule (guide 5.3 rule 8,
/// specs/AUTH.md 4.3): a request refused as unauthorized gets one session
/// renewal and one retry; if either is refused, the session ends. Network
/// failures never sign anyone out.
struct SessionRenewingBackendService: BackendService {
    private let base: any BackendService
    private let auth: any AuthService

    init(base: any BackendService, auth: any AuthService) {
        self.base = base
        self.auth = auth
    }

    func getEntry(locale: String) async throws(BackendError) -> ScreenEnvelope {
        try await withRenewal { () async throws(BackendError) in try await base.getEntry(locale: locale) }
    }

    func getScreen(key: String, locale: String, params: [String: JSONValue]) async throws(BackendError) -> ScreenEnvelope {
        try await withRenewal { () async throws(BackendError) in
            try await base.getScreen(key: key, locale: locale, params: params)
        }
    }

    func whoami() async throws(BackendError) -> Profile {
        try await withRenewal { () async throws(BackendError) in try await base.whoami() }
    }

    private func withRenewal<T>(_ request: () async throws(BackendError) -> T) async throws(BackendError) -> T {
        do {
            return try await request()
        } catch .unauthorized {
            switch await auth.renewAfterUnauthorized() {
            case .renewed:
                do {
                    return try await request()
                } catch .unauthorized {
                    await auth.endSession()
                    throw .unauthorized
                }
            case .network:
                throw .network
            case .refused, .notSignedIn:
                throw .unauthorized
            }
        }
    }
}
