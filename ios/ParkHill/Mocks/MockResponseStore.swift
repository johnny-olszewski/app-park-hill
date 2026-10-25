import Foundation

/// Reads mock responses (`/contract/mock_responses`), bundled into the Mock
/// configuration only. A persona's own mock response, in `<persona>/`, wins over the
/// shared one at the root.
struct MockResponseStore: Sendable {
    let root: URL

    /// The mock responses bundled with the app.
    static var bundled: MockResponseStore {
        guard let root = Bundle.main.url(forResource: "mock_responses", withExtension: nil) else {
            preconditionFailure("Mock responses are not bundled in this configuration")
        }
        return MockResponseStore(root: root)
    }

    /// The file name, without `.json`, of a call with params:
    /// `get_screen.community.group@group_id=<id>`, params sorted by name
    /// (contract/README.md, Mock responses). Only text and whole-number
    /// params are named; others give `name` alone.
    static func name(_ name: String, params: [String: JSONValue]) -> String {
        guard !params.isEmpty else { return name }
        var parts: [String] = []
        for (key, value) in params.sorted(by: { $0.key < $1.key }) {
            switch value {
            case .string(let text):
                parts.append("\(key)=\(text)")
            case .number(let number) where number == number.rounded():
                parts.append("\(key)=\(Int(number))")
            default:
                return name
            }
        }
        return name + "@" + parts.joined(separator: "&")
    }

    /// The mock response data for `name` (without `.json`), or nil when none exists.
    func data(named name: String, persona: String?) -> Data? {
        var candidates: [URL] = []
        if let persona {
            candidates.append(root.appending(path: persona).appending(path: "\(name).json"))
        }
        candidates.append(root.appending(path: "\(name).json"))
        return candidates.lazy.compactMap { try? Data(contentsOf: $0) }.first
    }
}
