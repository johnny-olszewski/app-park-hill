/// Sign-in, session and sign-out (specs/AUTH.md 6.1). Each configuration's
/// binding declares the concrete type as `AppAuthService`.
protocol AuthService: Sendable {
    /// Launch: whether a usable session exists. A stored session counts as
    /// signed in even when it cannot be renewed because the device is offline.
    func restoreSession() async -> AuthState

    /// Signs in through the backend. Failures carry the backend's code and
    /// message unchanged.
    func signIn(email: String, password: String) async throws(SignInError) -> AuthUser

    /// Revokes the session when online and always deletes everything about
    /// the user on the device.
    func signOut() async

    /// The current state first, then every change, including sign-outs the
    /// app did not ask for (renewal refused).
    func stateChanges() -> AsyncStream<AuthState>

    /// After a backend request was refused as unauthorized: renews the session
    /// once. A refused renewal ends the session (`sessionEnded`).
    func renewAfterUnauthorized() async -> SessionRenewal

    /// Signs out because access ended: wipes local data and emits
    /// `signedOut(.sessionEnded)`.
    func endSession() async
}

struct AuthUser: Equatable, Sendable {
    let id: String
    let email: String?
}

enum AuthState: Equatable, Sendable {
    case signedIn(AuthUser)
    /// `nil` reason: never signed in on this launch.
    case signedOut(SignOutReason?)
}

enum SignOutReason: Equatable, Sendable {
    /// The user signed out.
    case userRequest
    /// Access ended: renewal refused, account disabled or session revoked.
    case sessionEnded
}

enum SignInError: Error, Equatable, Sendable {
    /// The backend refused; show `message` as given.
    case rejected(code: String, message: String)
    /// No response arrived.
    case network
    /// A response arrived that does not match the contract.
    case unexpected
}

enum SessionRenewal: Equatable, Sendable {
    case renewed
    /// Renewal was refused; the session has been ended.
    case refused
    /// Renewal could not reach the backend; the session is kept.
    case network
    /// There was no session to renew.
    case notSignedIn
}
