import SwiftUI

/// `community.browse`: every group, for staff, with search filtering the
/// loaded rows by title on the device. Shown in a full-screen cover, which
/// is created anew each time it opens, so the search starts empty.
struct CommunityBrowseScreen: View {
    let data: CommunityBrowseData
    @State private var query = ""

    var body: some View {
        BrowseList(rows: Self.filter(data.rows, by: query))
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: data.searchPlaceholder)
            .navigationTitle(data.title)
    }

    /// Rows whose title contains `query`, ignoring case and surrounding
    /// spaces; all rows for an empty query.
    static func filter(_ rows: [GroupRow], by query: String) -> [GroupRow] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return rows }
        return rows.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
}

/// The browse rows, ending the search before a row opens its group: pushing
/// from an active search leaves the cover without its bar when it returns
/// (iOS 26).
private struct BrowseList: View {
    let rows: [GroupRow]
    @Environment(\.screenActions) private var actions
    @Environment(\.dismissSearch) private var dismissSearch

    var body: some View {
        GroupListView(title: nil, rows: rows)
            .environment(\.screenActions, ScreenActions(perform: { [actions, dismissSearch] action in
                dismissSearch()
                actions.perform(action)
            }))
    }
}
