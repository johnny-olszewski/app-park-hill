import Foundation
import Supabase
@testable import ParkHill

/// Calls backend functions that no app service exposes yet, for integration
/// tests only.
struct SupabaseBackendServiceProbe {
    let client: SupabaseClient

    /// The signed-in caller's id from `whoami()`; throws when refused.
    func whoamiID() async throws -> String {
        let profile: Profile = try await client.rpc("whoami").execute().value
        return profile.id
    }
}
