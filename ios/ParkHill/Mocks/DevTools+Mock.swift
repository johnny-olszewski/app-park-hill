// Compiled only in the Mock configuration (Config/App.xcconfig, DEV_TOOLS_SOURCES).

extension DevTools {
    /// The Mock build's own tools: sign-in persona and result, and switching persona.
    func registerEnvironmentTools(in registry: inout DevToolRegistry, services: AppServices) {
        MockSignInTools.register(
            in: &registry,
            choices: MockSignInChoices(scenario: .shared, personas: MockPersona.bundled),
            session: SessionTracker(auth: services.auth),
            auth: services.auth
        )
    }
}
