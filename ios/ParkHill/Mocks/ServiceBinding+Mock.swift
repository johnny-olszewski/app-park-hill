// Compiled only in the Mock configuration (Config/Mock.xcconfig).

typealias AppBackendService = MockBackendService
typealias AppAuthService = MockAuthService

enum ServiceBinding {
    static let environment = AppEnvironment.mock

    @MainActor
    static func makeScreenRegistry(services: AppServices, tracker: (any ScreenTracker)?) -> ScreenRegistry {
        var registry = ScreenRegistry(tracker: tracker)
        registry.registerSharedScreens(auth: services.auth)
        registry.registerMockScreens(auth: services.auth)
        return registry
    }
}
