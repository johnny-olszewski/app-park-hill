import Foundation
import Supabase

/// Calls backend functions that no app service exposes yet, for integration
/// tests only.
struct SupabaseBackendServiceProbe {
    let client: SupabaseClient

    private struct Profile: Decodable {
        let id: String
    }

    /// The signed-in caller's id from `whoami()`; throws when refused.
    func whoamiID() async throws -> String {
        let profile: Profile = try await client.rpc("whoami").execute().value
        return profile.id
    }
}
