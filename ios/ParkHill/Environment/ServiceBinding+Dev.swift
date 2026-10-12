// Compiled only in Dev configurations (Config/App.xcconfig).

typealias AppBackendService = SupabaseBackendService

enum ServiceBinding {
    static let environment = AppEnvironment(
        name: "Dev",
        backend: .fromInfoPlist()
    )
}
