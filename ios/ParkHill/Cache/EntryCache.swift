import Foundation

/// The last good entry envelope, one JSON file per locale (guide 5.3).
/// Lives under `CacheDirectory`, which sign-out deletes wholesale (IOS-005).
struct EntryCache: Sendable {
    let directory: URL

    static var standard: EntryCache {
        EntryCache(directory: CacheDirectory.url.appending(path: "entry", directoryHint: .isDirectory))
    }

    func load(locale: String) -> ScreenEnvelope? {
        guard let data = try? Data(contentsOf: fileURL(locale: locale)) else { return nil }
        return try? JSONDecoder().decode(ScreenEnvelope.self, from: data)
    }

    func save(_ envelope: ScreenEnvelope, locale: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(envelope).write(to: fileURL(locale: locale), options: .atomic)
    }

    private func fileURL(locale: String) -> URL {
        let safe = locale.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        return directory.appending(path: "\(safe.isEmpty ? "unknown" : safe).json")
    }
}

/// Root of everything the app caches about the user. Sign-out deletes it.
enum CacheDirectory {
    static var url: URL {
        URL.applicationSupportDirectory.appending(path: "Cache", directoryHint: .isDirectory)
    }
}
