// Compiled only in the Mock configuration (Config/Mock.xcconfig).

typealias AppBackendService = MockBackendService

enum ServiceBinding {
    static let environment = AppEnvironment.mock

    @MainActor
    static func makeScreenRegistry() -> ScreenRegistry {
        var registry = ScreenRegistry()
        registry.registerSharedScreens()
        registry.registerMockScreens()
        return registry
    }
}
