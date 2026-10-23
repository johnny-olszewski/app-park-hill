import Foundation
import os
@testable import ParkHill

/// Session storage in memory, so tests never touch the Keychain.
final class InMemoryAuthStorage: SupabaseSessionStorage {
    private let values = OSAllocatedUnfairLock<[String: Data]>(initialState: [:])

    func store(key: String, value: Data) throws { values.withLock { $0[key] = value } }
    func retrieve(key: String) throws -> Data? { values.withLock { $0[key] } }
    func remove(key: String) throws { values.withLock { _ = $0.removeValue(forKey: key) } }

    var isEmpty: Bool { values.withLock { $0.isEmpty } }
}

/// Test double for `AuthService`: fixed renewal, restore and sign-in
/// results, a state stream tests drive with `send`, and recorded calls.
final class StubAuthService: AuthService {
    private struct Calls {
        var renewals = 0
        var endSessions = 0
        var signOuts = 0
        var signIns: [String] = []
    }

    private let renewal: SessionRenewal
    private let restore: AuthState
    private let signInResult: Result<AuthUser, SignInError>
    private let calls = OSAllocatedUnfairLock(initialState: Calls())
    private let state: StateBroadcaster<AuthState>

    init(
        renewal: SessionRenewal = .notSignedIn,
        restore: AuthState = .signedOut(nil),
        signIn: Result<AuthUser, SignInError> = .failure(.unexpected)
    ) {
        self.renewal = renewal
        self.restore = restore
        self.signInResult = signIn
        self.state = StateBroadcaster(restore)
    }

    var renewals: Int { calls.withLock { $0.renewals } }
    var endSessions: Int { calls.withLock { $0.endSessions } }
    var signOuts: Int { calls.withLock { $0.signOuts } }
    var signIns: [String] { calls.withLock { $0.signIns } }

    /// Emits a state, as the real service does when access changes.
    func send(_ newState: AuthState) {
        state.send(newState)
    }

    func restoreSession() async -> AuthState { restore }

    func signIn(email: String, password: String) async throws(SignInError) -> AuthUser {
        calls.withLock { $0.signIns.append(email) }
        let user = try signInResult.get()
        state.send(.signedIn(user))
        return user
    }

    func signOut() async {
        calls.withLock { $0.signOuts += 1 }
        state.send(.signedOut(.userRequest))
    }

    func stateChanges() -> AsyncStream<AuthState> { state.stream() }

    func renewAfterUnauthorized() async -> SessionRenewal {
        calls.withLock { $0.renewals += 1 }
        return renewal
    }

    func endSession() async {
        calls.withLock { $0.endSessions += 1 }
        state.send(.signedOut(.sessionEnded))
    }
}

/// Builders for auth responses and stored sessions.
enum AuthMockResponses {
    static let userID = "9f6798b4-9e35-5b41-8207-9290979b50c3"

    /// An unsigned JWT whose payload carries `exp`, enough for the client to
    /// judge expiry.
    static func accessToken(expiresIn seconds: TimeInterval) -> String {
        let exp = Int(Date().timeIntervalSince1970 + seconds)
        func encode(_ json: String) -> String {
            Data(json.utf8).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        return [
            encode(#"{"alg":"HS256","typ":"JWT"}"#),
            encode(#"{"sub":"\#(userID)","role":"authenticated","exp":\#(exp)}"#),
            "signature",
        ].joined(separator: ".")
    }

    static let userJSON = """
    {"id":"\(userID)","aud":"authenticated","role":"authenticated","email":"attendee@parkhill.test",\
    "app_metadata":{"provider":"email"},"user_metadata":{},"identities":[],\
    "created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}
    """

    static func sessionJSON(expiresIn seconds: TimeInterval, refreshToken: String = "refresh-1") -> String {
        let expiresAt = Int(Date().timeIntervalSince1970 + seconds)
        return """
        {"access_token":"\(accessToken(expiresIn: seconds))","token_type":"bearer","expires_in":\(Int(seconds)),\
        "expires_at":\(expiresAt),"refresh_token":"\(refreshToken)","user":\(userJSON)}
        """
    }

    static func signInBody(expiresIn seconds: TimeInterval = 3600) -> String {
        """
        {"status":"ok","session":{"access_token":"\(accessToken(expiresIn: seconds))",\
        "refresh_token":"refresh-1","expires_at":\(Int(Date().timeIntervalSince1970 + seconds)),"user_id":"\(userID)"}}
        """
    }

    static let refusedRefreshBody = #"{"code":400,"error_code":"user_banned","msg":"User is banned"}"#
}

/// Folders standing in for the app's local user data.
struct TemporaryUserData {
    let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

    var localData: LocalUserData {
        LocalUserData(directories: [root.appending(path: "Cache"), root.appending(path: "UserFiles")])
    }

    /// Creates a file in each folder.
    func populate() throws {
        for directory in localData.directories {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data("x".utf8).write(to: directory.appending(path: "file"))
        }
    }

    var isEmpty: Bool {
        localData.directories.allSatisfy { !FileManager.default.fileExists(atPath: $0.path) }
    }

    func remove() {
        try? FileManager.default.removeItem(at: root)
    }
}

/// Personas and the local password, from the bundled `contract/seed/dataset.json`.
struct TestDataset: Decodable {
    struct Persona: Decodable {
        let id: String
        let email: String
        let state: String
    }

    let localPassword: String
    let personas: [Persona]

    enum CodingKeys: String, CodingKey {
        case localPassword = "local_password"
        case personas
    }

    private final class BundleToken {}

    static func load() throws -> TestDataset {
        let url = Bundle(for: BundleToken.self).url(forResource: "seed/dataset", withExtension: "json")!
        return try JSONDecoder().decode(TestDataset.self, from: Data(contentsOf: url))
    }

    func persona(_ id: String) -> Persona {
        personas.first { $0.id == id }!
    }
}
