import Foundation

/// Mock `AuthService`: signs in as a persona with no network. The persona is
/// shared with `MockBackendService`, which then returns that persona's
/// fixtures. What a sign-in does is chosen in the mock menu
/// (`MockSignInScenario`), not by the credentials typed. Not persisted: a
/// relaunch starts signed out.
final class MockAuthService: AuthService {
    private let personaState: MockPersonaState
    private let localData: LocalUserData
    private let scenario: MockSignInScenario
    private let fixtures: FixtureStore
    private let state = StateBroadcaster<AuthState>(.signedOut(nil))

    convenience init(environment: AppEnvironment) {
        self.init(personaState: .shared, localData: .standard, scenario: .shared, fixtures: .bundled)
    }

    init(personaState: MockPersonaState, localData: LocalUserData, scenario: MockSignInScenario, fixtures: FixtureStore) {
        self.personaState = personaState
        self.localData = localData
        self.scenario = scenario
        self.fixtures = fixtures
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

    /// Gives the result armed in the mock menu, whatever was typed: Success
    /// signs in as the chosen persona; a refusal throws its recorded message.
    func signIn(email: String, password: String) async throws(SignInError) -> AuthUser {
        let result = scenario.result
        switch result {
        case .success:
            return signIn(persona: scenario.persona)
        case .noConnection:
            throw .network
        case .somethingWentWrong:
            throw .unexpected
        case .invalidCredentials, .accountDisabled, .tooManyAttempts, .invalidRequest, .serverError:
            guard let name = result.refusalFixture,
                  let data = fixtures.data(named: name, persona: nil),
                  let refusal = try? JSONDecoder().decode(SignInFailure.self, from: data)
            else { throw .unexpected }
            throw .rejected(code: refusal.code, message: refusal.message)
        }
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
