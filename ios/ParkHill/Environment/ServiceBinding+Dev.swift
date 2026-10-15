// Compiled only in Dev configurations (Config/App.xcconfig).

typealias AppBackendService = SupabaseBackendService
typealias AppAuthService = SupabaseAuthService

enum ServiceBinding {
    static let environment = AppEnvironment(
        name: "Dev",
        backend: .fromInfoPlist(),
        showsBackendLabel: AppEnvironment.showsBackendLabel()
    )

    @MainActor
    static func makeScreenRegistry(services: AppServices, tracker: (any ScreenTracker)?) -> ScreenRegistry {
        var registry = ScreenRegistry(tracker: tracker)
        registry.registerSharedScreens(auth: services.auth)
        return registry
    }
}
