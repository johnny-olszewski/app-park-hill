// Compiled only in the Mock configuration (Config/Mock.xcconfig).

typealias AppBackendService = MockBackendService
typealias AppAuthService = MockAuthService

enum ServiceBinding {
    static let environment = AppEnvironment.mock

    @MainActor
    static func makeScreenRegistry(services: AppServices) -> ScreenRegistry {
        var registry = ScreenRegistry()
        registry.registerSharedScreens(auth: services.auth)
        registry.registerMockScreens(auth: services.auth)
        return registry
    }
}
