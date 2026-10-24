extension AppEnvironment {
    /// No backend: services read mock responses and make no network calls.
    static let mock = AppEnvironment(name: "Mock", backend: nil)
}
