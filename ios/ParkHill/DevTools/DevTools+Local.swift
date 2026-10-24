// Compiled only in Local debug configurations (Config/App.xcconfig, DEV_TOOLS_SOURCES).

extension DevTools {
    /// Local talks to a real backend, so it adds no tools beyond the app tools.
    func registerEnvironmentTools(in registry: inout DevToolRegistry, services: AppServices) {}
}
