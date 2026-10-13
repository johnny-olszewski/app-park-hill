import Foundation
import Testing
@testable import ParkHill

struct MockAuthServiceTests {
    private let personaState = MockPersonaState()
    private let userData = TemporaryUserData()

    private func makeService() -> MockAuthService {
        MockAuthService(personaState: personaState, localData: userData.localData)
    }

    @Test func startsSignedOut() async {
        #expect(await makeService().restoreSession() == .signedOut(nil))
    }

    @Test func personaSignInSwitchesTheBackendToThatPersonasFixtures() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root.appending(path: "admin"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data(#"{"key":"shared","data":{}}"#.utf8).write(to: root.appending(path: "get_screen.home.json"))
        try Data(#"{"key":"admin","data":{}}"#.utf8).write(to: root.appending(path: "admin/get_screen.home.json"))
        let backend = MockBackendService(fixtures: FixtureStore(root: root), personaState: personaState)
        let auth = makeService()

        #expect(try await backend.getScreen(key: "home", locale: "en").key == "shared")
        let user = auth.signIn(persona: "admin")
        #expect(user.id == "admin")
        #expect(await auth.restoreSession() == .signedIn(user))
        #expect(try await backend.getScreen(key: "home", locale: "en").key == "admin")
    }

    @Test func emailSignInUsesThePersonaNamedByTheEmail() async throws {
        let auth = makeService()
        let user = try await auth.signIn(email: "attendee@parkhill.test", password: "anything")
        #expect(user.id == "attendee")
        #expect(personaState.current == "attendee")
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
