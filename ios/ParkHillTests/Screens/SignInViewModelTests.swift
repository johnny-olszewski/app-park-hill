import Foundation
import Testing
@testable import ParkHill

@MainActor
struct SignInViewModelTests {
    private let data = SignInScreenData(
        title: "Sign in", emailLabel: "Email", passwordLabel: "Password", submitLabel: "Sign in",
        cannotConnectMessage: "Can't connect.", sessionEndedMessage: "You've been signed out.",
        secondaryActions: []
    )

    private func makeModel(_ auth: StubAuthService) -> SignInViewModel {
        let model = SignInViewModel(data: data, auth: auth)
        model.email = " attendee@parkhill.test "
        model.password = "secret"
        return model
    }

    @Test func screenDataDecodesFromTheMockResponse() throws {
        let envelope = try JSONDecoder().decode(ScreenEnvelope.self, from: TestMockResponses.data("get_entry.json"))
        let decoded = try JSONDecoder().decode(SignInScreenData.self, from: JSONEncoder().encode(envelope.data))
        #expect(decoded.title == "Sign in")
        #expect(!decoded.cannotConnectMessage.isEmpty)
        #expect(!decoded.sessionEndedMessage.isEmpty)
    }

    @Test func submitNeedsAnEmailAndPassword() {
        let model = SignInViewModel(data: data, auth: StubAuthService())
        #expect(!model.canSubmit)
        model.email = "a@b.c"
        #expect(!model.canSubmit)
        model.password = "x"
        #expect(model.canSubmit)
    }

    @Test func successSendsTheTrimmedEmailAndClearsThePassword() async {
        let auth = StubAuthService(signIn: .success(AuthUser(id: "u1", email: "attendee@parkhill.test")))
        let model = makeModel(auth)

        await model.submit()

        #expect(auth.signIns == ["attendee@parkhill.test"])
        #expect(model.password.isEmpty)
        #expect(model.errorMessage == nil)
        #expect(model.connectionMessage == nil)
    }

    @Test func refusalShowsTheBackendMessageExactly() async {
        let model = makeModel(StubAuthService(signIn: .failure(.rejected(code: "invalid_credentials", message: "That email and password don't match."))))

        await model.submit()

        #expect(model.errorMessage == "That email and password don't match.")
        #expect(model.connectionMessage == nil)
        #expect(model.hasAttempted)
    }

    @Test(arguments: [SignInError.network, .unexpected])
    func noUsableAnswerShowsTheCannotConnectMessage(error: SignInError) async {
        let model = makeModel(StubAuthService(signIn: .failure(error)))

        await model.submit()

        #expect(model.connectionMessage == "Can't connect.")
        #expect(model.errorMessage == nil)
    }
}
