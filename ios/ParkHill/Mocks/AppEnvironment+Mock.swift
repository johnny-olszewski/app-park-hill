extension AppEnvironment {
    /// No backend: services read contract fixtures and make no network calls.
    static let mock = AppEnvironment(name: "Mock", backend: nil)
}
