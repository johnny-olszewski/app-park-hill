import OSLog
import SwiftUI

@main
struct ParkHillApp: App {
    /// Debug builds: the dev tools pill and menu. Release builds: nothing.
    private let devTools: AppDevTools
    @State private var coordinator: AppCoordinator

    init() {
        let environment = ServiceBinding.environment
        Theme.applyNavigationBarAppearance()
        Logger.app.info("Environment \(environment.name, privacy: .public), backend \(environment.backendLabel, privacy: .public)")
        let services = AppServices(environment: environment)
        let devTools = AppDevTools(environment: environment, services: services)
        self.devTools = devTools
        _coordinator = State(initialValue: AppCoordinator(
            backend: services.backend,
            auth: services.auth,
            registry: ServiceBinding.makeScreenRegistry(services: services, tracker: devTools.screenTracker),
            cache: .standard
        ))
    }

    var body: some Scene {
        WindowGroup {
            devTools.attach(to: AppRootView(coordinator: coordinator))
        }
    }
}
