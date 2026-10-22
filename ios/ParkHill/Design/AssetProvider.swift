import SwiftUI

/// Resolves the backend's image keys to bundled assets (guide decision log:
/// bundled first, remote later behind this type). Placeholder SF Symbols until
/// design delivers artwork under the same keys.
enum AssetProvider {
    private static let tabIcons = [
        "tab.home": "house",
        "tab.community": "person.3",
    ]

    /// The icon for a tab's `icon_key`; an unknown key gets the fallback, so a
    /// new key from the backend can never break the tab bar.
    static func tabIcon(_ key: String) -> Image {
        Image(systemName: tabIcons[key] ?? "square.grid.2x2")
    }

    /// Whether `key` has its own bundled icon rather than the fallback.
    static func hasTabIcon(_ key: String) -> Bool {
        tabIcons[key] != nil
    }
}
