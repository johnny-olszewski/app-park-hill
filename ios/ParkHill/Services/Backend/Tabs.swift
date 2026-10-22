/// The signed-in app's tabs (`get_tabs`, contract/README.md): in backend
/// order, each with its root screen embedded.
struct TabsResponse: Codable, Equatable, Sendable {
    let tabs: [TabItem]
}

/// One tab: its title for the locale, a bundled icon key and its root screen.
struct TabItem: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let iconKey: String
    let screen: ScreenEnvelope

    enum CodingKeys: String, CodingKey {
        case id, title, screen
        case iconKey = "icon_key"
    }
}
