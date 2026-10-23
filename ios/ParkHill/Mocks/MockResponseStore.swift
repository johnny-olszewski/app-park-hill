import Foundation

/// Reads contract fixtures (`/contract/mock_responses`), bundled into the Mock
/// configuration only. A persona's own fixture, in `<persona>/`, wins over the
/// shared one at the root.
struct MockResponseStore: Sendable {
    let root: URL

    /// The fixtures bundled with the app.
    static var bundled: MockResponseStore {
        guard let root = Bundle.main.url(forResource: "mock_responses", withExtension: nil) else {
            preconditionFailure("Mock responses are not bundled in this configuration")
        }
        return MockResponseStore(root: root)
    }

    /// The fixture data for `name` (without `.json`), or nil when none exists.
    func data(named name: String, persona: String?) -> Data? {
        var candidates: [URL] = []
        if let persona {
            candidates.append(root.appending(path: persona).appending(path: "\(name).json"))
        }
        candidates.append(root.appending(path: "\(name).json"))
        return candidates.lazy.compactMap { try? Data(contentsOf: $0) }.first
    }
}
