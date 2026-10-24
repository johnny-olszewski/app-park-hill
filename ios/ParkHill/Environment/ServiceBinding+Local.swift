// Compiled only in Local configurations (Config/App.xcconfig).

typealias AppBackendService = SupabaseBackendService
typealias AppAuthService = SupabaseAuthService

enum ServiceBinding {
    static let environment = AppEnvironment(name: "Local", backend: .fromInfoPlist())

    @MainActor
    static func makeScreenRegistry(services: AppServices, tracker: (any ScreenTracker)?) -> ScreenRegistry {
        var registry = ScreenRegistry(tracker: tracker)
        registry.registerSharedScreens(auth: services.auth)
        return registry
    }
}
