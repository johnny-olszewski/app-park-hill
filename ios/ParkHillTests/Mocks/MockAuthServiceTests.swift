import Foundation
import Testing
@testable import ParkHill

struct MockAuthServiceTests {
    private let personaState = MockPersonaState()
    private let userData = TemporaryUserData()
    private let scenario = MockSignInScenario(persona: "admin")

    private func makeService() -> MockAuthService {
        MockAuthService(personaState: personaState, localData: userData.localData, scenario: scenario, responses: .bundled)
    }

    private func recorded(_ name: String) throws -> SignInFailure {
        try JSONDecoder().decode(SignInFailure.self, from: TestMockResponses.data("\(name).json"))
    }

    @Test func startsSignedOut() async {
        #expect(await makeService().restoreSession() == .signedOut(nil))
    }

    @Test func personaSignInSwitchesTheBackendToThatPersonasMockResponses() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root.appending(path: "admin"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data(#"{"key":"shared","data":{}}"#.utf8).write(to: root.appending(path: "get_screen.home.json"))
        try Data(#"{"key":"admin","data":{}}"#.utf8).write(to: root.appending(path: "admin/get_screen.home.json"))
        let backend = MockBackendService(responses: MockResponseStore(root: root), personaState: personaState)
        let auth = makeService()

        #expect(try await backend.getScreen(key: "home", locale: "en").key == "shared")
        let user = auth.signIn(persona: "admin")
        #expect(user.id == "admin")
        #expect(await auth.restoreSession() == .signedIn(user))
        #expect(try await backend.getScreen(key: "home", locale: "en").key == "admin")
    }

    @Test func successSignsInAsTheChosenPersonaWhateverIsTyped() async throws {
        let user = try await makeService().signIn(email: "attendee@parkhill.test", password: "anything")
        #expect(user.id == "admin")
        #expect(personaState.current == "admin")
    }

    @Test(arguments: [
        (MockSignInResult.invalidCredentials, "sign_in.error"),
        (.accountDisabled, "sign_in.error.account_disabled"),
        (.tooManyAttempts, "sign_in.error.too_many_attempts"),
        (.invalidRequest, "sign_in.error.invalid_request"),
        (.serverError, "sign_in.error.unknown"),
    ])
    func aRefusalThrowsItsRecordedMessage(result: MockSignInResult, mockResponse: String) async throws {
        scenario.result = result
        let expected = try recorded(mockResponse)
        await #expect(throws: SignInError.rejected(code: expected.code, message: expected.message)) {
            _ = try await makeService().signIn(email: "x", password: "y")
        }
        #expect(personaState.current == nil)
    }

    @Test func noConnectionAndSomethingWentWrongAreClientFailures() async {
        scenario.result = .noConnection
        await #expect(throws: SignInError.network) { _ = try await makeService().signIn(email: "x", password: "y") }
        scenario.result = .somethingWentWrong
        await #expect(throws: SignInError.unexpected) { _ = try await makeService().signIn(email: "x", password: "y") }
    }

    @Test func theSharedScenarioStartsWithTheFirstActivePersonaAndSuccess() throws {
        let firstActive = try TestDataset.load().personas.first { $0.state == "active" }?.id
        #expect(MockSignInScenario.shared.persona == firstActive)
        #expect(MockSignInScenario.shared.result == .success)
    }

    @Test func bundledPersonasAreTheActiveOnesInDatasetOrder() throws {
        let dataset = try TestDataset.load()
        #expect(MockPersona.bundled.map(\.id) == dataset.personas.filter { $0.state == "active" }.map(\.id))
    }

    @Test func signOutClearsThePersonaAndWipesData() async throws {
        defer { userData.remove() }
        let auth = makeService()
        auth.signIn(persona: "attendee")
        try userData.populate()
        var states = auth.stateChanges().makeAsyncIterator()
        _ = await states.next()

        await auth.signOut()

        #expect(await states.next() == .signedOut(.userRequest))
        #expect(personaState.current == nil)
        #expect(userData.isEmpty)
    }

    @Test func endSessionEmitsSessionEnded() async {
        let auth = makeService()
        auth.signIn(persona: "attendee")
        await auth.endSession()
        #expect(await auth.restoreSession() == .signedOut(.sessionEnded))
        #expect(await auth.renewAfterUnauthorized() == .notSignedIn)
    }

    @Test func appServicesShareOnePersonaBetweenTheMockServices() {
        #expect(MockAuthService(environment: .mock) !== MockAuthService(environment: .mock))
        let before = MockPersonaState.shared.current
        defer { MockPersonaState.shared.current = before }
        MockAuthService(environment: .mock).signIn(persona: "admin")
        #expect(MockPersonaState.shared.current == "admin")
    }
}
