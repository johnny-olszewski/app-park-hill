import Foundation
import Testing
@testable import ParkHill

@MainActor
struct MockSignInToolsTests {
    private let personas = [
        MockPersona(id: "attendee", displayName: "Attendee", description: "A"),
        MockPersona(id: "admin", displayName: "Admin", description: "B"),
    ]

    @Test func choicesWriteThroughToTheScenario() {
        let scenario = MockSignInScenario(persona: "attendee")
        let choices = MockSignInChoices(scenario: scenario, personas: personas)
        choices.persona = "admin"
        choices.result = .tooManyAttempts
        #expect(scenario.persona == "admin")
        #expect(scenario.result == .tooManyAttempts)
    }

    @Test func onlyAFailureIsAWarning() {
        let choices = MockSignInChoices(scenario: MockSignInScenario(persona: "attendee"), personas: personas)
        #expect(choices.warning == nil)
        choices.result = .tooManyAttempts
        #expect(choices.warning == "Next sign-in will fail: Too many attempts")
    }

    @Test func signInToolsAreOnTheSignInScreenAndSwitchPersonaIsEverywhere() {
        let choices = MockSignInChoices(scenario: MockSignInScenario(persona: "attendee"), personas: personas)
        let auth = MockAuthService(personaState: MockPersonaState(), localData: TemporaryUserData().localData, scenario: MockSignInScenario(persona: "attendee"), fixtures: .bundled)
        var registry = DevToolRegistry()
        MockSignInTools.register(in: &registry, choices: choices, session: SessionTracker(auth: auth), auth: auth)

        #expect(registry.tools(forScreen: "auth.sign_in").map(\.id) == ["mock.signIn.persona", "mock.signIn.result"])
        #expect(registry.appTools.map(\.id) == ["mock.switchPersona"])
        #expect(registry.warnings.isEmpty)
        choices.result = .noConnection
        #expect(registry.warnings == ["Next sign-in will fail: No connection"])
    }

    @Test func everyResultHasATitleAndRefusalsHaveRecordings() throws {
        for result in MockSignInResult.allCases {
            #expect(!result.title.isEmpty)
            if let name = result.refusalFixture {
                _ = try TestFixtures.data("\(name).json")
            }
        }
    }
}
