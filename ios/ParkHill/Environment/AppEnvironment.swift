import Foundation

/// The environment this build targets. Each configuration's binding file
/// declares exactly one value (guide 5.2); app code never checks which.
struct AppEnvironment: Sendable {
    /// Configuration name, for example "Mock" or "Local".
    let name: String
    /// The backend this build talks to, or nil when it has none.
    let backend: BackendTarget?

    /// Human-readable backend target, for the launch log.
    var backendLabel: String {
        backend?.url.absoluteString ?? "none"
    }
}

/// A Supabase backend: API URL and anon key.
struct BackendTarget: Sendable {
    let url: URL
    let anonKey: String
}

extension BackendTarget {
    /// Reads the backend values that the configuration's xcconfig writes into
    /// Info.plist. Missing or malformed values are a build configuration bug.
    static func fromInfoPlist(_ bundle: Bundle = .main) -> BackendTarget {
        guard
            let urlString = bundle.object(forInfoDictionaryKey: "BackendURL") as? String,
            let url = URL(string: urlString),
            url.scheme != nil,
            let anonKey = bundle.object(forInfoDictionaryKey: "BackendAnonKey") as? String,
            !anonKey.isEmpty
        else {
            fatalError("BackendURL and BackendAnonKey must be set by the configuration's xcconfig")
        }
        return BackendTarget(url: url, anonKey: anonKey)
    }
}
