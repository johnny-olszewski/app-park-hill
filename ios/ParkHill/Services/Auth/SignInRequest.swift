/// The `sign_in` Edge Function request body (contract/README.md, specs/AUTH.md 5.5).
/// Its responses are the generated `SignInSuccess` and `SignInFailure`.
struct SignInRequest: Encodable, Sendable {
    let email: String
    let password: String
    let locale: String
}
