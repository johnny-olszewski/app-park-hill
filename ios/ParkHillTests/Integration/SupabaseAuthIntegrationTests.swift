import Foundation
import Testing
@testable import ParkHill

/// Dev only: signs in against the configured backend (local Supabase by
/// default) with the real Keychain. Start it first:
/// `cd backend && supabase start && supabase db reset`.
@Suite(.serialized)
struct SupabaseAuthIntegrationTests {
    private let dataset: TestDataset
    private let storageKey = "integration-\(UUID().uuidString)"
    private let userData = TemporaryUserData()

    init() throws {
        dataset = try TestDataset.load()
    }

    private func makeService() -> (SupabaseAuthService, SupabaseBackendServiceProbe) {
        let client = SupabaseClientProvider.makeClient(environment: ServiceBinding.environment, authStorageKey: storageKey)
        return (
            SupabaseAuthService(client: client, localData: userData.localData),
            SupabaseBackendServiceProbe(client: client)
        )
    }

    @Test func signInReachesTheBackendAndSignOutEndsAccess() async throws {
        defer { userData.remove() }
        let attendee = dataset.persona("attendee")
        let (auth, probe) = makeService()

        let user = try await auth.signIn(email: attendee.email, password: dataset.localPassword)
        #expect(user.email == attendee.email)
        #expect(try await probe.whoamiID() == user.id)

        // The session is in the Keychain: a new client with the same storage finds it.
        let (restored, _) = makeService()
        #expect(await restored.restoreSession() == .signedIn(user))

        await auth.signOut()
        await #expect(throws: (any Error).self) { _ = try await probe.whoamiID() }
        #expect(await makeService().0.restoreSession() == .signedOut(nil))
    }

    @Test func signedInTabsMatchTheFixtureAndSignedOutIsRefused() async throws {
        defer { userData.remove() }
        let attendee = dataset.persona("attendee")
        let client = SupabaseClientProvider.makeClient(environment: ServiceBinding.environment, authStorageKey: storageKey)
        let auth = SupabaseAuthService(client: client, localData: userData.localData)
        let backend = SupabaseBackendService(client: client)

        await #expect(throws: BackendError.unauthorized) { _ = try await backend.getTabs(locale: "en") }

        _ = try await auth.signIn(email: attendee.email, password: dataset.localPassword)
        let fixture = try JSONDecoder().decode(TabsResponse.self, from: TestFixtures.data("attendee/get_tabs.json"))
        #expect(try await backend.getTabs(locale: "en") == fixture)
        await auth.signOut()
    }

    @Test func unknownEmailIsRejectedWithTheBackendsMessage() async {
        let (auth, _) = makeService()
        do {
            _ = try await auth.signIn(email: "nobody@parkhill.test", password: "not-the-password")
            Issue.record("expected sign-in to be refused")
        } catch {
            guard case .rejected(let code, let message) = error else {
                Issue.record("unexpected error \(error)")
                return
            }
            #expect(code == "invalid_credentials")
            #expect(!message.isEmpty)
        }
    }

    @Test func disabledPersonaIsRefused() async {
        let (auth, _) = makeService()
        await #expect(throws: SignInError.self) {
            _ = try await auth.signIn(email: dataset.persona("disabled").email, password: dataset.localPassword)
        }
    }
}
