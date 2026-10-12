import OSLog
import SwiftUI

@main
struct ParkHillApp: App {
    @State private var coordinator: AppCoordinator

    init() {
        let environment = ServiceBinding.environment
        Logger.app.info("Environment \(environment.name, privacy: .public), backend \(environment.backendLabel, privacy: .public)")
        let services = AppServices(environment: environment)
        _coordinator = State(initialValue: AppCoordinator(
            backend: services.backend,
            registry: ServiceBinding.makeScreenRegistry(),
            cache: .standard
        ))
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(coordinator: coordinator)
        }
    }
}
