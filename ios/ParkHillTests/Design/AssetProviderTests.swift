import Foundation
import Testing
@testable import ParkHill

/// Tab icon keys resolve to bundled icons, with a fallback (IOS-008 AC7).
struct AssetProviderTests {
    @Test func everyRecordedTabIconIsBundled() throws {
        for path in TestFixtures.allJSONPaths().filter({ $0.hasSuffix("/get_tabs.json") }) {
            let response = try JSONDecoder().decode(TabsResponse.self, from: TestFixtures.data(path))
            for tab in response.tabs {
                #expect(AssetProvider.hasTabIcon(tab.iconKey), "\(path): \(tab.iconKey)")
            }
        }
    }

    @Test func anUnknownKeyGetsTheFallback() {
        #expect(!AssetProvider.hasTabIcon("tab.future"))
        #expect(AssetProvider.tabIcon("tab.future") == AssetProvider.tabIcon("tab.another_future"))
    }
}
