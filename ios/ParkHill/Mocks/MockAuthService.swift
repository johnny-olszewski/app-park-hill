/// Mock `AuthService`: signs in as a persona with no network. The persona is
/// shared with `MockBackendService`, which then returns that persona's
/// fixtures. Not persisted: a relaunch starts signed out.
final class MockAuthService: AuthService {
    private let personaState: MockPersonaState
    private let localData: LocalUserData
    private let state = StateBroadcaster<AuthState>(.signedOut(nil))

    convenience init(environment: AppEnvironment) {
        self.init(personaState: .shared, localData: .standard)
    }

    init(personaState: MockPersonaState, localData: LocalUserData) {
        self.personaState = personaState
        self.localData = localData
        if let persona = personaState.current {
            state.send(.signedIn(Self.user(persona: persona)))
        }
    }

    /// Mock only: signs in as a persona from `contract/seed/dataset.json`.
    @discardableResult
    func signIn(persona: String) -> AuthUser {
        personaState.current = persona
        let user = Self.user(persona: persona)
        state.send(.signedIn(user))
        return user
    }

    func restoreSession() async -> AuthState {
        state.value
    }

    /// Signs in as the persona named by the email's local part, for example
    /// `admin@parkhill.test` as `admin`. Any password is accepted.
    func signIn(email: String, password: String) async throws(SignInError) -> AuthUser {
        let persona = email.split(separator: "@").first.map(String.init) ?? ""
        guard !persona.isEmpty else { throw .unexpected }
        return signIn(persona: persona)
    }

    func signOut() async {
        personaState.current = nil
        localData.wipe()
        state.send(.signedOut(.userRequest))
    }

    func stateChanges() -> AsyncStream<AuthState> {
        state.stream()
    }

    func renewAfterUnauthorized() async -> SessionRenewal {
        personaState.current == nil ? .notSignedIn : .renewed
    }

    func endSession() async {
        personaState.current = nil
        localData.wipe()
        state.send(.signedOut(.sessionEnded))
    }

    private static func user(persona: String) -> AuthUser {
        AuthUser(id: persona, email: nil)
    }
}
