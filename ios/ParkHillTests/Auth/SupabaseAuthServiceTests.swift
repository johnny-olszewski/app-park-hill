import Foundation
import Testing
@testable import ParkHill

/// SupabaseAuthService against a stubbed transport and in-memory session
/// storage: no backend needed, so these run in Mock CI as well as Dev.
@Suite(.serialized)
struct SupabaseAuthServiceTests {
    private static let environment = AppEnvironment(
        name: "Dev",
        backend: BackendTarget(url: URL(string: "http://backend.test")!, anonKey: "test-anon-key")
    )

    private let storage = InMemoryAuthStorage()
    private let userData = TemporaryUserData()

    private func makeService() -> SupabaseAuthService {
        let client = SupabaseClientProvider.makeClient(
            environment: Self.environment,
            session: StubURLProtocol.makeSession(),
            authStorage: storage,
            authStorageKey: "test-session"
        )
        return SupabaseAuthService(client: client, localData: userData.localData, locale: { "en" })
    }

    /// A service holding a stored session that is valid, or already expired.
    private func signedInService(expired: Bool = false) async throws -> SupabaseAuthService {
        let service = makeService()
        if expired {
            // An expired token makes the client refresh at once; the refresh
            // returns an expired session, which is what gets stored.
            StubURLProtocol.stub(routes: [
                "/functions/v1/sign_in": .http(status: 200, body: AuthFixtures.signInBody(expiresIn: -60)),
                "/auth/v1/token": .http(status: 200, body: AuthFixtures.sessionJSON(expiresIn: -60)),
            ])
        } else {
            StubURLProtocol.stub(routes: [
                "/functions/v1/sign_in": .http(status: 200, body: AuthFixtures.signInBody()),
                "/auth/v1/user": .http(status: 200, body: AuthFixtures.userJSON),
            ])
        }
        _ = try await service.signIn(email: "attendee@parkhill.test", password: "pw")
        #expect(!storage.isEmpty)
        return service
    }

    private func paths() -> [String] {
        StubURLProtocol.requests.compactMap { $0.url?.path }
    }

    // MARK: Sign in (AC2, AC3)

    @Test func signInSendsCredentialsOnlyToTheFunctionAndStoresTheSession() async throws {
        defer { userData.remove() }
        let service = makeService()
        StubURLProtocol.stub(routes: [
            "/functions/v1/sign_in": .http(status: 200, body: AuthFixtures.signInBody()),
            "/auth/v1/user": .http(status: 200, body: AuthFixtures.userJSON),
        ])

        let user = try await service.signIn(email: "attendee@parkhill.test", password: "secret")

        #expect(user == AuthUser(id: AuthFixtures.userID, email: "attendee@parkhill.test"))
        let request = try #require(StubURLProtocol.requests.first)
        #expect(request.url?.path == "/functions/v1/sign_in")
        #expect(request.value(forHTTPHeaderField: "X-App-Config") == "dev")
        #expect(request.value(forHTTPHeaderField: "X-App-Platform") == "ios")
        #expect(request.value(forHTTPHeaderField: "X-App-Version") != nil)
        #expect(request.value(forHTTPHeaderField: "Accept-Language") != nil)
        let body = try JSONDecoder().decode([String: String].self, from: #require(request.bodyData))
        #expect(body == ["email": "attendee@parkhill.test", "password": "secret", "locale": "en"])
        #expect(!paths().contains("/auth/v1/token"), "the password must go only to sign_in")
        #expect(!storage.isEmpty)
        #expect(await service.restoreSession() == .signedIn(user))
    }

    @Test func rejectedSignInReturnsTheBackendCodeAndMessageUnchanged() async throws {
        let fixture = try JSONDecoder().decode(SignInFailure.self, from: TestFixtures.data("sign_in.error.json"))
        StubURLProtocol.stub(routes: [
            "/functions/v1/sign_in": .http(status: 401, body: String(decoding: try TestFixtures.data("sign_in.error.json"), as: UTF8.self)),
        ])
        await #expect(throws: SignInError.rejected(code: fixture.code, message: fixture.message)) {
            _ = try await makeService().signIn(email: "attendee@parkhill.test", password: "wrong")
        }
        #expect(storage.isEmpty)
    }

    @Test func signInWithoutNetworkIsANetworkError() async {
        StubURLProtocol.stub(.failure(.notConnectedToInternet))
        await #expect(throws: SignInError.network) {
            _ = try await makeService().signIn(email: "attendee@parkhill.test", password: "pw")
        }
    }

    @Test func malformedSignInResponseIsUnexpected() async {
        StubURLProtocol.stub(routes: ["/functions/v1/sign_in": .http(status: 200, body: "{}")])
        await #expect(throws: SignInError.unexpected) {
            _ = try await makeService().signIn(email: "attendee@parkhill.test", password: "pw")
        }
    }

    // MARK: Restore (AC4, AC5)

    @Test func restoreWithoutAStoredSessionIsSignedOut() async {
        StubURLProtocol.stub(.failure(.notConnectedToInternet))
        #expect(await makeService().restoreSession() == .signedOut(nil))
    }

    @Test func restoreWithAValidStoredSessionNeedsNoNetwork() async throws {
        defer { userData.remove() }
        let service = try await signedInService()
        StubURLProtocol.stub(.failure(.notConnectedToInternet))

        #expect(await service.restoreSession() == .signedIn(AuthUser(id: AuthFixtures.userID, email: "attendee@parkhill.test")))
        #expect(StubURLProtocol.requests.isEmpty)
    }

    @Test func restoreRenewsAnExpiredSession() async throws {
        defer { userData.remove() }
        let service = try await signedInService(expired: true)
        StubURLProtocol.stub(routes: ["/auth/v1/token": .http(status: 200, body: AuthFixtures.sessionJSON(expiresIn: 3600, refreshToken: "refresh-2"))])

        guard case .signedIn = await service.restoreSession() else {
            Issue.record("expected signed in")
            return
        }
        #expect(paths() == ["/auth/v1/token"])
    }

    @Test func restoreOfflineWithAnExpiredSessionStaysSignedIn() async throws {
        defer { userData.remove() }
        let service = try await signedInService(expired: true)
        StubURLProtocol.stub(.failure(.notConnectedToInternet))

        guard case .signedIn = await service.restoreSession() else {
            Issue.record("expected signed in while offline")
            return
        }
        #expect(!storage.isEmpty)
    }

    @Test func restoreWithARefusedRenewalEndsTheSessionAndWipesData() async throws {
        defer { userData.remove() }
        let service = try await signedInService(expired: true)
        try userData.populate()
        StubURLProtocol.stub(routes: ["/auth/v1/token": .http(status: 400, body: AuthFixtures.refusedRefreshBody)])

        #expect(await service.restoreSession() == .signedOut(.sessionEnded))
        #expect(storage.isEmpty)
        #expect(userData.isEmpty)
    }

    // MARK: Renewal after unauthorized (AC5, AC6)

    @Test func renewalAfterUnauthorizedSucceeds() async throws {
        defer { userData.remove() }
        let service = try await signedInService()
        StubURLProtocol.stub(routes: ["/auth/v1/token": .http(status: 200, body: AuthFixtures.sessionJSON(expiresIn: 3600, refreshToken: "refresh-2"))])
        #expect(await service.renewAfterUnauthorized() == .renewed)
    }

    @Test func refusedRenewalEmitsSessionEndedAndWipesData() async throws {
        defer { userData.remove() }
        let service = try await signedInService()
        try userData.populate()
        var states = service.stateChanges().makeAsyncIterator()
        _ = await states.next()
        StubURLProtocol.stub(routes: ["/auth/v1/token": .http(status: 400, body: AuthFixtures.refusedRefreshBody)])

        #expect(await service.renewAfterUnauthorized() == .refused)
        #expect(await states.next() == .signedOut(.sessionEnded))
        #expect(storage.isEmpty)
        #expect(userData.isEmpty)
    }

    @Test func renewalWithoutNetworkKeepsTheSession() async throws {
        defer { userData.remove() }
        let service = try await signedInService()
        StubURLProtocol.stub(.failure(.notConnectedToInternet))

        #expect(await service.renewAfterUnauthorized() == .network)
        #expect(!storage.isEmpty)
        guard case .signedIn = await service.restoreSession() else {
            Issue.record("expected still signed in")
            return
        }
    }

    @Test func renewalWithoutASessionReportsNotSignedIn() async {
        #expect(await makeService().renewAfterUnauthorized() == .notSignedIn)
    }

    // MARK: Sign out (AC7)

    @Test func signOutRevokesAndDeletesEverything() async throws {
        defer { userData.remove() }
        let service = try await signedInService()
        try userData.populate()
        StubURLProtocol.stub(routes: ["/auth/v1/logout": .http(status: 204, body: "")])

        await service.signOut()

        #expect(paths().contains("/auth/v1/logout"))
        #expect(storage.isEmpty)
        #expect(userData.isEmpty)
        #expect(await service.restoreSession() == .signedOut(nil))
    }

    @Test func signOutOfflineStillDeletesEverything() async throws {
        defer { userData.remove() }
        let service = try await signedInService()
        try userData.populate()
        var states = service.stateChanges().makeAsyncIterator()
        _ = await states.next()
        StubURLProtocol.stub(.failure(.notConnectedToInternet))

        await service.signOut()

        #expect(await states.next() == .signedOut(.userRequest))
        #expect(storage.isEmpty)
        #expect(userData.isEmpty)
    }
}
