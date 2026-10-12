/// Composition root. Constructs the services this configuration's binding
/// declares; never checks which configuration it is.
struct AppServices: Sendable {
    let environment: AppEnvironment
    let backend: any BackendService

    init(environment: AppEnvironment) {
        self.environment = environment
        self.backend = AppBackendService(environment: environment)
    }
}
