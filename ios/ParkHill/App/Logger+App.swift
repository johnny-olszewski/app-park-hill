import Foundation
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "ParkHill"

    static let app = Logger(subsystem: subsystem, category: "app")
}
