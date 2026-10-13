import OSLog
import SwiftUI

@main
struct ParkHillApp: App {
    private let environment = ServiceBinding.environment
    @State private var coordinator: AppCoordinator

    init() {
        let environment = ServiceBinding.environment
        Theme.applyNavigationBarAppearance()
        Logger.app.info("Environment \(environment.name, privacy: .public), backend \(environment.backendLabel, privacy: .public)")
        let services = AppServices(environment: environment)
        _coordinator = State(initialValue: AppCoordinator(
            backend: services.backend,
            auth: services.auth,
            registry: ServiceBinding.makeScreenRegistry(services: services),
            cache: .standard
        ))
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(coordinator: coordinator, environment: environment)
        }
    }
}
