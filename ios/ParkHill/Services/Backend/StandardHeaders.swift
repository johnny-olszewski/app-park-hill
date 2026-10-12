import Foundation

/// Labels sent on every backend request (specs/AUTH.md 5.6). For logging and
/// diagnostics only; the backend never uses them for access decisions.
enum StandardHeaders {
    static func make(
        environment: AppEnvironment,
        bundle: Bundle = .main,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> [String: String] {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return [
            "X-App-Config": environment.name.lowercased(),
            "X-App-Platform": "ios",
            "X-App-Version": "\(version) (\(build))",
            "Accept-Language": preferredLanguages.first ?? "en",
        ]
    }
}
