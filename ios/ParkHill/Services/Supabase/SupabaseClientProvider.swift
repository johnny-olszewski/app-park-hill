import Foundation
import os
import Supabase

/// Session storage the Supabase client accepts; lets tests supply one without
/// importing the SDK.
typealias SupabaseSessionStorage = AuthLocalStorage

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

    /// A new client. Use `client(for:)` in app code; tests pass their own
    /// transport and session storage. The default storage is the Keychain.
    static func makeClient(
        environment: AppEnvironment,
        session: URLSession = .shared,
        authStorage: (any SupabaseSessionStorage)? = nil,
        authStorageKey: String? = nil
    ) -> SupabaseClient {
        guard let backend = environment.backend else {
            preconditionFailure("Environment \(environment.name) has no backend")
        }
        let auth = if let authStorage {
            SupabaseClientOptions.AuthOptions(
                storage: authStorage, storageKey: authStorageKey, emitLocalSessionAsInitialSession: true
            )
        } else {
            SupabaseClientOptions.AuthOptions(storageKey: authStorageKey, emitLocalSessionAsInitialSession: true)
        }
        return SupabaseClient(
            supabaseURL: backend.url,
            supabaseKey: backend.anonKey,
            options: SupabaseClientOptions(
                auth: auth,
                global: .init(
                    headers: StandardHeaders.make(environment: environment),
                    session: session
                )
            )
        )
    }
}
