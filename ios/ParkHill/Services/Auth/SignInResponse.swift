/// `sign_in` Edge Function responses (contract/README.md, specs/AUTH.md 5.5).
struct SignInSuccess: Decodable, Equatable, Sendable {
    struct Session: Decodable, Equatable, Sendable {
        let accessToken: String
        let refreshToken: String
        let expiresAt: Double
        let userId: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresAt = "expires_at"
            case userId = "user_id"
        }
    }

    let status: String
    let session: Session
}

struct SignInFailure: Decodable, Equatable, Sendable {
    let status: String
    let code: String
    let message: String
}

/// The request body.
struct SignInRequest: Encodable, Sendable {
    let email: String
    let password: String
    let locale: String
}
