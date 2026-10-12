import Foundation
import os
import Supabase

/// Owns the one Supabase client the app uses. Backend and auth services share
/// it, so the session token is attached to backend calls automatically.
enum SupabaseClientProvider {
    private static let shared = OSAllocatedUnfairLock<SupabaseClient?>(initialState: nil)

    /// The shared client, created on first use from the environment's backend.
    static func client(for environment: AppEnvironment) -> SupabaseClient {
        shared.withLock { client in
            if let client { return client }
            let created = makeClient(environment: environment)
            client = created
            return created
        }
    }

    /// A new client. Use `client(for:)` in app code; tests pass their own session.
    static func makeClient(environment: AppEnvironment, session: URLSession = .shared) -> SupabaseClient {
        guard let backend = environment.backend else {
            preconditionFailure("Environment \(environment.name) has no backend")
        }
        return SupabaseClient(
            supabaseURL: backend.url,
            supabaseKey: backend.anonKey,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true),
                global: .init(
                    headers: StandardHeaders.make(environment: environment),
                    session: session
                )
            )
        )
    }
}
