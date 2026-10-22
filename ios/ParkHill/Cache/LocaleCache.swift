import Foundation

/// The last good response of one kind, one JSON file per locale (guide 5.3).
/// Every cache lives under `CacheDirectory`, which sign-out deletes wholesale
/// (IOS-005).
struct LocaleCache<Value: Codable & Sendable>: Sendable {
    let directory: URL

    func load(locale: String) -> Value? {
        guard let data = try? Data(contentsOf: fileURL(locale: locale)) else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    func save(_ value: Value, locale: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(value).write(to: fileURL(locale: locale), options: .atomic)
    }

    private func fileURL(locale: String) -> URL {
        let safe = locale.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        return directory.appending(path: "\(safe.isEmpty ? "unknown" : safe).json")
    }

    fileprivate static func standard(named name: String) -> LocaleCache {
        LocaleCache(directory: CacheDirectory.url.appending(path: name, directoryHint: .isDirectory))
    }
}

/// The last good signed-out entry screen.
typealias EntryCache = LocaleCache<ScreenEnvelope>

/// The last good signed-in tabs, with their root screens.
typealias TabsCache = LocaleCache<TabsResponse>

extension LocaleCache where Value == ScreenEnvelope {
    static var standard: EntryCache { .standard(named: "entry") }
}

extension LocaleCache where Value == TabsResponse {
    static var standard: TabsCache { .standard(named: "tabs") }
}

/// Root of everything the app caches about the user. Sign-out deletes it.
enum CacheDirectory {
    static var url: URL {
        URL.applicationSupportDirectory.appending(path: "Cache", directoryHint: .isDirectory)
    }
}
