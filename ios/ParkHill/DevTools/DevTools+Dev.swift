// Compiled only in Dev debug configurations (Config/App.xcconfig, DEV_TOOLS_SOURCES).

extension DevTools {
    /// Dev talks to a real backend, so it adds no tools beyond the app tools.
    func registerEnvironmentTools(in registry: inout DevToolRegistry, services: AppServices) {}
}
