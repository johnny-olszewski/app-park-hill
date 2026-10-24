import CryptoKit
import Foundation

/// The last good copy of every backend screen, per screen key, params and
/// locale (guide 5.3 rule 10). Lives under `CacheDirectory`, so sign-out
/// deletes it with everything else.
struct ScreenCache: Sendable {
    let directory: URL

    static var standard: ScreenCache {
        ScreenCache(directory: CacheDirectory.url.appending(path: "screens", directoryHint: .isDirectory))
    }

    func load(key: String, params: [String: JSONValue], locale: String) -> ScreenEnvelope? {
        guard let data = try? Data(contentsOf: fileURL(key: key, params: params, locale: locale)) else { return nil }
        return try? JSONDecoder().decode(ScreenEnvelope.self, from: data)
    }

    func save(_ envelope: ScreenEnvelope, params: [String: JSONValue], locale: String) throws {
        let url = fileURL(key: envelope.key, params: params, locale: locale)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(envelope).write(to: url, options: .atomic)
    }

    /// One file per key and params, hashed so any params make a safe name.
    private func fileURL(key: String, params: [String: JSONValue], locale: String) -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let identity = Data(key.utf8) + Data([0]) + ((try? encoder.encode(params)) ?? Data())
        let name = SHA256.hash(data: identity).map { String(format: "%02x", $0) }.joined()
        let safeLocale = locale.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        return directory
            .appending(path: safeLocale.isEmpty ? "unknown" : safeLocale, directoryHint: .isDirectory)
            .appending(path: "\(name).json")
    }
}
