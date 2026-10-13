import Foundation

/// The environment this build targets. Each configuration's binding file
/// declares exactly one value (guide 5.2); app code never checks which.
struct AppEnvironment: Sendable {
    /// Configuration name, for example "Mock" or "Dev".
    let name: String
    /// The backend this build talks to, or nil when it has none.
    let backend: BackendTarget?
    /// Whether screens show which backend this build targets: every
    /// non-release build (guide 5.2 rule 5). Set by the build configuration.
    var showsBackendLabel: Bool = false

    /// Human-readable backend target, for the launch log and debug UI.
    var backendLabel: String {
        backend?.url.absoluteString ?? "none"
    }

    /// Configuration and backend, for the on-screen label.
    var targetLabel: String {
        "\(name) · \(backend?.url.absoluteString ?? "no network")"
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

extension AppEnvironment {
    /// Reads the `ShowBackendLabel` value the configuration writes into
    /// Info.plist (YES in debug configurations, NO in release).
    static func showsBackendLabel(_ bundle: Bundle = .main) -> Bool {
        (bundle.object(forInfoDictionaryKey: "ShowBackendLabel") as? String) == "YES"
    }
}
