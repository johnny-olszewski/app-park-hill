import OSLog
import SwiftUI

@main
struct ParkHillApp: App {
    private let services: AppServices

    init() {
        let environment = ServiceBinding.environment
        Logger.app.info("Environment \(environment.name, privacy: .public), backend \(environment.backendLabel, privacy: .public)")
        services = AppServices(environment: environment)
    }

    var body: some Scene {
        WindowGroup {
            PlaceholderView()
        }
    }
}
