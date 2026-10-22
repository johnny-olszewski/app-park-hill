import Foundation
import os
import Supabase

/// Production `AuthService`: signs in through the backend's `sign_in`
/// function, then hands the session to the shared Supabase client, which
/// stores it in the Keychain and renews it. Renewal and sign-out use the
/// client library directly (specs/AUTH.md 5.5 rule 3).
final class SupabaseAuthService: AuthService {
    private let client: SupabaseClient
    private let localData: LocalUserData
    private let locale: @Sendable () -> String
    private let state = StateBroadcaster<AuthState>(.signedOut(nil))
    /// True while the app itself is signing out, so the client's resulting
    /// `signedOut` event is not mistaken for access ending.
    private let signingOut = OSAllocatedUnfairLock(initialState: false)
    private let observation = OSAllocatedUnfairLock<Task<Void, Never>?>(initialState: nil)

    convenience init(environment: AppEnvironment) {
        self.init(client: SupabaseClientProvider.client(for: environment), localData: .standard)
    }

    init(
        client: SupabaseClient,
        localData: LocalUserData,
        locale: @escaping @Sendable () -> String = { AppLocale.current() }
    ) {
        self.client = client
        self.localData = localData
        self.locale = locale
        observeClientEvents()
    }

    deinit {
        observation.withLock { $0?.cancel() }
    }

    // MARK: AuthService

    func restoreSession() async -> AuthState {
        guard let stored = client.auth.currentSession else {
            state.send(.signedOut(nil))
            return state.value
        }
        do {
            let session = try await client.auth.session
            state.send(.signedIn(Self.user(session.user)))
        } catch where Self.isTransient(error) {
            // Offline: the stored session still counts (specs/AUTH.md 4.3 rule 5).
            state.send(.signedIn(Self.user(stored.user)))
        } catch {
            await endSession()
        }
        return state.value
    }

    func signIn(email: String, password: String) async throws(SignInError) -> AuthUser {
        signingOut.withLock { $0 = false }
        let success: SignInSuccess
        do {
            success = try await client.functions.invoke(
                EdgeFunction.signIn.rawValue,
                options: FunctionInvokeOptions(body: SignInRequest(email: email, password: password, locale: locale()))
            )
        } catch {
            throw Self.signInError(error)
        }
        guard success.status == "ok" else { throw .unexpected }

        let session: Session
        do {
            session = try await client.auth.setSession(
                accessToken: success.session.accessToken,
                refreshToken: success.session.refreshToken
            )
        } catch {
            throw Self.isTransient(error) ? .network : .unexpected
        }
        let user = Self.user(session.user)
        state.send(.signedIn(user))
        return user
    }

    func signOut() async {
        await clearSession()
        state.send(.signedOut(.userRequest))
    }

    func stateChanges() -> AsyncStream<AuthState> {
        state.stream()
    }

    func renewAfterUnauthorized() async -> SessionRenewal {
        guard client.auth.currentSession != nil else { return .notSignedIn }
        do {
            let session = try await client.auth.refreshSession()
            state.send(.signedIn(Self.user(session.user)))
            return .renewed
        } catch where Self.isTransient(error) {
            return .network
        } catch {
            await endSession()
            return .refused
        }
    }

    func endSession() async {
        await clearSession()
        state.send(.signedOut(.sessionEnded))
    }

    // MARK: Private

    /// Deletes the session (revoking it when online) and all local user data.
    private func clearSession() async {
        signingOut.withLock { $0 = true }
        // The client removes the stored session before calling the server, so
        // this succeeds locally even offline.
        try? await client.auth.signOut()
        localData.wipe()
    }

    /// Reacts to sign-outs the client performs itself, for example when the
    /// server reports the session no longer exists during renewal.
    private func observeClientEvents() {
        let changes = client.auth.authStateChanges
        let task = Task { [weak self] in
            for await change in changes {
                guard let self else { return }
                switch change.event {
                case .signedOut:
                    let appInitiated = signingOut.withLock { $0 }
                    if !appInitiated, case .signedIn = state.value {
                        localData.wipe()
                        state.send(.signedOut(.sessionEnded))
                    }
                case .tokenRefreshed:
                    if let session = change.session { state.send(.signedIn(Self.user(session.user))) }
                default:
                    break
                }
            }
        }
        observation.withLock { $0 = task }
    }

    private static func user(_ user: User) -> AuthUser {
        AuthUser(id: user.id.uuidString.lowercased(), email: user.email)
    }

    private static func signInError(_ error: any Error) -> SignInError {
        switch error {
        case FunctionsError.httpError(_, let data):
            guard let failure = try? JSONDecoder().decode(SignInFailure.self, from: data) else {
                return .unexpected
            }
            return .rejected(code: failure.code, message: failure.message)
        case is URLError:
            return .network
        default:
            return .unexpected
        }
    }

    /// Failures that say nothing about the session's validity: no response,
    /// or a server-side outage.
    private static func isTransient(_ error: any Error) -> Bool {
        switch error {
        case is URLError, is CancellationError:
            return true
        case let AuthError.api(_, _, _, response):
            return response.statusCode >= 500
        default:
            return false
        }
    }
}
