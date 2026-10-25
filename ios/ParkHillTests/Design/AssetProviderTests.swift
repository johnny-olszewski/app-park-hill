import Foundation
import Testing
@testable import ParkHill

/// Tab and toolbar icon keys resolve to bundled icons, with a fallback
/// (IOS-008 AC7, IOS-025).
struct AssetProviderTests {
    @Test func everyRecordedTabIconIsBundled() throws {
        for path in TestMockResponses.allJSONPaths().filter({ $0.hasSuffix("/get_tabs.json") }) {
            let response = try JSONDecoder().decode(TabsResponse.self, from: TestMockResponses.data(path))
            for tab in response.tabs {
                #expect(AssetProvider.hasTabIcon(tab.iconKey), "\(path): \(tab.iconKey)")
            }
        }
    }

    @Test func anUnknownKeyGetsTheFallback() {
        #expect(!AssetProvider.hasTabIcon("tab.future"))
        #expect(AssetProvider.tabIcon("tab.future") == AssetProvider.tabIcon("tab.another_future"))
    }

    @Test func everyRecordedToolbarIconIsBundled() throws {
        for path in TestMockResponses.screenEnvelopePaths() {
            let envelope = try JSONDecoder().decode(ScreenEnvelope.self, from: TestMockResponses.data(path))
            for item in envelope.toolbar ?? [] {
                #expect(AssetProvider.hasToolbarIcon(item.iconKey), "\(path): \(item.iconKey)")
            }
        }
    }

    @Test func anUnknownToolbarKeyGetsTheFallback() {
        #expect(!AssetProvider.hasToolbarIcon("toolbar.future"))
        #expect(AssetProvider.toolbarIcon("toolbar.future") == AssetProvider.toolbarIcon("toolbar.another_future"))
    }
}
