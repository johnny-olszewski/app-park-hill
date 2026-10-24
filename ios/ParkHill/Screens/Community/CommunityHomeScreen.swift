import SwiftUI

/// What Community home shows, inferred from which part of its data is
/// present, checked in this order (specs/COMMUNITY.md 4.1).
enum CommunityHomeState: Equatable {
    case group(GroupDetail)
    case myGroups(GroupList)
    case empty(EmptyState)

    /// Nil when none of the parts is present: the data is unusable.
    init?(_ data: CommunityHomeData) {
        if let group = data.group {
            self = .group(group)
        } else if let myGroups = data.myGroups {
            self = .myGroups(myGroups)
        } else if let empty = data.empty {
            self = .empty(empty)
        } else {
            return nil
        }
    }
}

/// The Community tab's root: the person's one group, their groups, or an
/// empty message with no buttons. The tab title stays the one get_tabs sends.
struct CommunityHomeScreen: View {
    let data: CommunityHomeData

    var body: some View {
        switch CommunityHomeState(data) {
        case .group(let group):
            GroupDetailView(detail: group)
        case .myGroups(let list):
            GroupListView(list: list)
        case .empty(let empty):
            EmptyStateView(empty: empty)
        case nil:
            // Never resolved: the registry refuses unusable data.
            EmptyView()
        }
    }
}

/// A backend message in place of content, with no buttons.
struct EmptyStateView: View {
    let empty: EmptyState

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(empty.title)
                    .font(.phHeading)
                    .foregroundStyle(Color.phInk)
                    .accessibilityIdentifier("emptyState.title")
            } icon: {
                Image(systemName: "person.3").foregroundStyle(Color.phInkMuted)
            }
        } description: {
            Text(empty.message)
                .foregroundStyle(Color.phInk)
                .accessibilityIdentifier("emptyState.message")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.phSurface)
    }
}
