import SwiftUI

/// A titled list of groups: one row per GroupRow, performing its action when
/// tapped. A client component shared by every screen that lists groups.
struct GroupListView: View {
    let list: GroupList

    var body: some View {
        List {
            Section {
                ForEach(list.rows, id: \.groupId) { row in
                    GroupRowView(row: row)
                }
            } header: {
                Text(list.title)
                    .brandLabel()
                    .accessibilityIdentifier("groupList.title")
            }
            .listRowBackground(Color.phSurfaceRaised)
        }
        .scrollContentBackground(.hidden)
        .background(Color.phSurface)
    }
}

/// One group: title, subtitle and optional badge. Tappable only when this
/// build knows its action.
struct GroupRowView: View {
    let row: GroupRow
    @Environment(\.screenActions) private var actions

    var body: some View {
        if actions.canPerform(row.action) {
            Button {
                actions.perform(row.action)
            } label: {
                content(chevron: true)
            }
            .accessibilityIdentifier("groupRow")
        } else {
            content(chevron: false)
        }
    }

    private func content(chevron: Bool) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .foregroundStyle(Color.phInk)
                    .lineLimit(1)
                Text(row.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.phInkMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let badge = row.badge {
                Text(badge)
                    .font(.caption2.weight(.semibold))
                    .tracking(0.7)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.phInk)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.phSky))
            }
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.phInkMuted)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
    }
}
