import Foundation
import Testing
@testable import ParkHill

struct EntryCacheTests {
    private let cache = EntryCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))

    @Test func emptyCacheReturnsNil() {
        #expect(cache.load(locale: "en") == nil)
    }

    @Test func savedEnvelopeLoadsBackForItsLocale() throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        try cache.save(.signIn(title: "Sign in"), locale: "en")
        try cache.save(.signIn(title: "Iniciar sesión"), locale: "es")

        #expect(cache.load(locale: "en") == .signIn(title: "Sign in"))
        #expect(cache.load(locale: "es") == .signIn(title: "Iniciar sesión"))
        #expect(cache.load(locale: "fr") == nil)
    }

    @Test func saveReplacesThePreviousEnvelope() throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        try cache.save(.signIn(title: "Old"), locale: "en")
        try cache.save(.signIn(title: "New"), locale: "en")
        #expect(cache.load(locale: "en") == .signIn(title: "New"))
    }

    @Test func standardCacheLivesUnderTheDeletableCacheDirectory() {
        #expect(EntryCache.standard.directory.path.hasPrefix(CacheDirectory.url.path))
    }

    @Test func localeIsReducedToItsLanguageCode() {
        #expect(AppLocale.current(preferredLanguages: ["en-US"]) == "en")
        #expect(AppLocale.current(preferredLanguages: ["es-MX", "en"]) == "es")
        #expect(AppLocale.current(preferredLanguages: []) == "en")
    }
}

struct TabsCacheTests {
    private let cache = TabsCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))

    @Test func savedTabsLoadBackForTheirLocale() throws {
        defer { try? FileManager.default.removeItem(at: cache.directory) }
        let tabs = TabsResponse.tabs(("home", "home.root"), ("community", "community.home"))
        try cache.save(tabs, locale: "en")
        #expect(cache.load(locale: "en") == tabs)
        #expect(cache.load(locale: "es") == nil)
    }

    @Test func standardCacheLivesUnderTheDeletableCacheDirectory() {
        #expect(TabsCache.standard.directory.path.hasPrefix(CacheDirectory.url.path))
        #expect(TabsCache.standard.directory != EntryCache.standard.directory)
    }
}
