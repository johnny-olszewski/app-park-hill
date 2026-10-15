import Foundation
import os

/// What the next mock sign-in does (specs/AUTH.md 5.4), chosen in the mock menu.
enum MockSignInResult: String, CaseIterable, Identifiable, Sendable {
    case success
    case invalidCredentials
    case accountDisabled
    case tooManyAttempts
    case invalidRequest
    case serverError
    case noConnection
    case somethingWentWrong

    var id: String { rawValue }

    var title: String {
        switch self {
        case .success: "Success"
        case .invalidCredentials: "Wrong email or password"
        case .accountDisabled: "Account disabled"
        case .tooManyAttempts: "Too many attempts"
        case .invalidRequest: "Invalid request"
        case .serverError: "Server error"
        case .noConnection: "No connection"
        case .somethingWentWrong: "Something went wrong"
        }
    }

    /// The recorded `sign_in` refusal this result replays, without `.json`,
    /// or nil when it is not a backend refusal.
    var refusalFixture: String? {
        switch self {
        case .invalidCredentials: "sign_in.error"
        case .accountDisabled: "sign_in.error.account_disabled"
        case .tooManyAttempts: "sign_in.error.too_many_attempts"
        case .invalidRequest: "sign_in.error.invalid_request"
        case .serverError: "sign_in.error.unknown"
        case .success, .noConnection, .somethingWentWrong: nil
        }
    }
}

/// A persona the Mock build can sign in as.
struct MockPersona: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let description: String

    /// The active personas in `contract/seed/dataset.json`, in dataset order.
    static func active(inDatasetAt url: URL) throws -> [MockPersona] {
        struct Dataset: Decodable {
            struct Persona: Decodable {
                let id: String
                let display_name: String
                let description: String
                let state: String
            }
            let personas: [Persona]
        }
        return try JSONDecoder().decode(Dataset.self, from: Data(contentsOf: url)).personas
            .filter { $0.state == "active" }
            .map { MockPersona(id: $0.id, displayName: $0.display_name, description: $0.description) }
    }

    /// The active personas in the dataset bundled with the Mock build.
    static var bundled: [MockPersona] {
        guard let url = Bundle.main.url(forResource: "seed/dataset", withExtension: "json"),
              let personas = try? active(inDatasetAt: url)
        else {
            preconditionFailure("contract/seed/dataset.json is not bundled in this configuration")
        }
        return personas
    }
}

/// The persona and next sign-in result chosen in the mock menu. Kept for the
/// launch; shared by the mock auth service and the menu.
final class MockSignInScenario: Sendable {
    struct Choice: Equatable, Sendable {
        var persona: String
        var result: MockSignInResult
    }

    /// The one instance the running Mock app shares: the first bundled
    /// persona, signing in successfully.
    static let shared = MockSignInScenario(persona: MockPersona.bundled.first?.id ?? "")

    private let choice: OSAllocatedUnfairLock<Choice>

    init(persona: String, result: MockSignInResult = .success) {
        choice = OSAllocatedUnfairLock(initialState: Choice(persona: persona, result: result))
    }

    var persona: String {
        get { choice.withLock { $0.persona } }
        set { choice.withLock { $0.persona = newValue } }
    }

    var result: MockSignInResult {
        get { choice.withLock { $0.result } }
        set { choice.withLock { $0.result = newValue } }
    }
}
