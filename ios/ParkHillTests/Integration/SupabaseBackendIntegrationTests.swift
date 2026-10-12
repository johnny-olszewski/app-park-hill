import Foundation
import Testing
@testable import ParkHill

/// Dev only: calls the configured backend (local Supabase by default). Start it
/// first: `cd backend && supabase start && supabase db reset`.
struct SupabaseBackendIntegrationTests {
    private let service = SupabaseBackendService(environment: ServiceBinding.environment)

    @Test func entryIsTheSignInScreenAndMatchesTheFixture() async throws {
        let envelope = try await service.getEntry(locale: "en")
        let fixture = try JSONDecoder().decode(ScreenEnvelope.self, from: TestFixtures.data("get_entry.json"))
        #expect(envelope.key == "auth.sign_in")
        #expect(envelope == fixture)
    }

    @Test func unknownScreenKeyThrowsUnknownScreen() async {
        await #expect(throws: BackendError.unknownScreen) {
            _ = try await service.getScreen(key: "does.not_exist", locale: "en")
        }
    }
}
