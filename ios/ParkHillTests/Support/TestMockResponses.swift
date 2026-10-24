import Foundation

/// Mock responses bundled into the test target, in every configuration.
enum TestMockResponses {
    private final class BundleToken {}

    static var root: URL {
        Bundle(for: BundleToken.self).url(forResource: "mock_responses", withExtension: nil)!
    }

    static func data(_ relativePath: String) throws -> Data {
        try Data(contentsOf: root.appending(path: relativePath))
    }

    /// Every `.json` file under the mock responses root, as paths relative to it.
    static func allJSONPaths() -> [String] {
        let rootPath = root.standardizedFileURL.path + "/"
        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        return (enumerator?.allObjects as? [URL] ?? [])
            .filter { $0.pathExtension == "json" }
            .map { $0.standardizedFileURL.path.replacingOccurrences(of: rootPath, with: "") }
            .sorted()
    }

    /// `contract/responses.json`: each mock response's name (its file name
    /// without the persona folder or `.json`) to the contract type it decodes as.
    static func responseTypes() throws -> [String: String] {
        let url = Bundle(for: BundleToken.self).url(forResource: "responses", withExtension: "json")!
        return try JSONDecoder().decode([String: String].self, from: Data(contentsOf: url))
    }

    /// Mock responses of screen responses (`get_entry`, `get_screen`), in any persona
    /// folder. Other mock responses, such as `get_tabs.json` and `sign_in.*.json`,
    /// have their own models.
    static func screenEnvelopePaths() -> [String] {
        allJSONPaths().filter {
            let name = ($0 as NSString).lastPathComponent
            return name == "get_entry.json" || name.hasPrefix("get_screen.")
        }
    }
}
