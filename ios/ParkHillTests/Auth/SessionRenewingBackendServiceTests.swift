import Testing
@testable import ParkHill

/// The unauthorized rule: one renewal and one retry, then sign-out; network
/// failures never sign out (IOS-005 AC6).
struct SessionRenewingBackendServiceTests {
    private func makeService(
        _ results: Result<ScreenEnvelope, BackendError>...,
        renewal: SessionRenewal
    ) -> (SessionRenewingBackendService, StubBackendService, StubAuthService) {
        let backend = StubBackendService(environment: .init(name: "Stub", backend: nil))
        backend.enqueueEntry(results)
        let auth = StubAuthService(renewal: renewal)
        return (SessionRenewingBackendService(base: backend, auth: auth), backend, auth)
    }

    @Test func successNeedsNoRenewal() async throws {
        let (service, backend, auth) = makeService(.success(.signIn()), renewal: .renewed)
        _ = try await service.getEntry(locale: "en")
        #expect(backend.entryCalls.count == 1)
        #expect(auth.renewals == 0)
    }

    @Test func unauthorizedRenewsOnceAndRetries() async throws {
        let (service, backend, auth) = makeService(.failure(.unauthorized), .success(.signIn()), renewal: .renewed)
        #expect(try await service.getEntry(locale: "en") == .signIn())
        #expect(backend.entryCalls.count == 2)
        #expect(auth.renewals == 1)
        #expect(auth.endSessions == 0)
    }

    @Test func unauthorizedAgainAfterRenewalEndsTheSession() async {
        let (service, backend, auth) = makeService(.failure(.unauthorized), .failure(.unauthorized), renewal: .renewed)
        await #expect(throws: BackendError.unauthorized) { _ = try await service.getEntry(locale: "en") }
        #expect(backend.entryCalls.count == 2)
        #expect(auth.renewals == 1)
        #expect(auth.endSessions == 1)
    }

    @Test func refusedRenewalDoesNotRetry() async {
        let (service, backend, auth) = makeService(.failure(.unauthorized), .success(.signIn()), renewal: .refused)
        await #expect(throws: BackendError.unauthorized) { _ = try await service.getEntry(locale: "en") }
        #expect(backend.entryCalls.count == 1)
        #expect(auth.renewals == 1)
    }

    @Test func renewalWithoutNetworkKeepsTheSession() async {
        let (service, _, auth) = makeService(.failure(.unauthorized), renewal: .network)
        await #expect(throws: BackendError.network) { _ = try await service.getEntry(locale: "en") }
        #expect(auth.endSessions == 0)
    }

    @Test func networkErrorsNeverRenewOrSignOut() async {
        let (service, _, auth) = makeService(.failure(.network), renewal: .renewed)
        await #expect(throws: BackendError.network) { _ = try await service.getEntry(locale: "en") }
        #expect(auth.renewals == 0)
        #expect(auth.endSessions == 0)
    }

    @Test func unauthorizedWhileSignedOutIsPassedThrough() async {
        let (service, backend, auth) = makeService(.failure(.unauthorized), renewal: .notSignedIn)
        await #expect(throws: BackendError.unauthorized) { _ = try await service.getEntry(locale: "en") }
        #expect(backend.entryCalls.count == 1)
        #expect(auth.endSessions == 0)
    }
}
