import Foundation

/// Contract fixtures bundled into the test target, in every configuration.
enum TestFixtures {
    private final class BundleToken {}

    static var root: URL {
        Bundle(for: BundleToken.self).url(forResource: "fixtures", withExtension: nil)!
    }

    static func data(_ relativePath: String) throws -> Data {
        try Data(contentsOf: root.appending(path: relativePath))
    }

    /// Every `.json` file under the fixtures root, as paths relative to it.
    static func allJSONPaths() -> [String] {
        let rootPath = root.standardizedFileURL.path + "/"
        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        return (enumerator?.allObjects as? [URL] ?? [])
            .filter { $0.pathExtension == "json" }
            .map { $0.standardizedFileURL.path.replacingOccurrences(of: rootPath, with: "") }
            .sorted()
    }
}
