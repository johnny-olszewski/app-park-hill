import SwiftUI

/// A screen's toolbar items from its envelope, in backend order, in the
/// system toolbar: the label is each icon's accessibility label, and the
/// system moves what its bar cannot fit into its overflow menu.
struct BackendToolbar: ToolbarContent {
    let items: [ToolbarItem]
    @Environment(\.screenActions) private var actions

    var body: some ToolbarContent {
        SwiftUI.ToolbarItemGroup(placement: .primaryAction) {
            ForEach(Self.shown(items, actions: actions), id: \.id) { item in
                Button {
                    actions.perform(item.action)
                } label: {
                    Label {
                        Text(item.label)
                    } icon: {
                        AssetProvider.toolbarIcon(item.iconKey)
                    }
                }
                .accessibilityIdentifier("toolbar.\(item.id)")
            }
        }
    }

    /// The items to draw, in backend order: those whose action this build knows.
    static func shown(_ items: [ToolbarItem], actions: ScreenActions) -> [ToolbarItem] {
        items.filter { actions.canPerform($0.action) }
    }
}
