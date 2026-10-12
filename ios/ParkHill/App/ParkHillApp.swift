import OSLog
import SwiftUI

@main
struct ParkHillApp: App {
    init() {
        let environment = ServiceBinding.environment
        Logger.app.info("Environment \(environment.name, privacy: .public), backend \(environment.backendLabel, privacy: .public)")
    }

    var body: some Scene {
        WindowGroup {
            PlaceholderView()
        }
    }
}
