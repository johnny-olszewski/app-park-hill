/// Composition root. Constructs the services this configuration's binding
/// declares; never checks which configuration it is.
struct AppServices: Sendable {
    let environment: AppEnvironment
    /// The concrete type, so the Mock binding can reach mock-only sign-in.
    let auth: AppAuthService
    /// Backend calls with the unauthorized rule applied: one renewal and
    /// retry, then sign-out.
    let backend: any BackendService

    init(environment: AppEnvironment) {
        self.environment = environment
        let auth = AppAuthService(environment: environment)
        self.auth = auth
        self.backend = SessionRenewingBackendService(
            base: AppBackendService(environment: environment),
            auth: auth
        )
    }
}
