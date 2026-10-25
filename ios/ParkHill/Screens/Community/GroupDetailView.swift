import SwiftUI

/// A group's details and members (specs/COMMUNITY.md 5.1, 5.2): swipe to
/// remove on rows the backend sends `remove` for, and a Leave footer when it
/// sends `leave`. A client component shared by `community.group` and
/// Community home's one group; every word comes from the data.
struct GroupDetailView: View {
    let detail: GroupDetail
    @Environment(\.screenActions) private var actions

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(detail.title)
                        .font(.phHeading)
                        .foregroundStyle(Color.phInk)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("groupDetail.title")
                    if !detail.description.isEmpty {
                        Text(detail.description)
                            .foregroundStyle(Color.phInkMuted)
                            .accessibilityIdentifier("groupDetail.description")
                    }
                }
                .padding(.vertical, 4)
                if !detail.meeting.isEmpty {
                    DetailLine(text: detail.meeting, systemImage: "calendar", identifier: "groupDetail.meeting")
                }
                if !detail.location.isEmpty {
                    DetailLine(text: detail.location, systemImage: "mappin.and.ellipse", identifier: "groupDetail.location")
                }
                DetailLine(text: detail.leadersLine, systemImage: "star", identifier: "groupDetail.leadersLine")
            }
            .listRowBackground(Color.phSurfaceRaised)

            Section {
                ForEach(detail.members, id: \.userId) { member in
                    MemberRowView(member: member)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            // A destructive role would animate the row away
                            // before the confirmation, so the button is only
                            // tinted. It is also VoiceOver's action for the row.
                            if let remove = member.remove {
                                Button(remove.label) { actions.perform(remove.action) }
                                    .tint(Color.phDanger)
                                    .accessibilityIdentifier("groupDetail.remove")
                            }
                        }
                }
            } header: {
                Text(detail.membersTitle)
                    .brandLabel()
                    .accessibilityIdentifier("groupDetail.membersTitle")
            }
            .listRowBackground(Color.phSurfaceRaised)

            if let leave = detail.leave {
                Section {
                    Button(role: .destructive) {
                        actions.perform(leave.action)
                    } label: {
                        Text(leave.label).frame(maxWidth: .infinity)
                    }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityIdentifier("groupDetail.leave")
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.phSurface)
    }
}

/// One backend-formatted line of the details, with a symbol for scanning.
private struct DetailLine: View {
    let text: String
    let systemImage: String
    let identifier: String

    var body: some View {
        Label {
            Text(text).foregroundStyle(Color.phInk)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(Color.phInkMuted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}

/// A member: initials, name, the leader icon and the note (such as "You").
struct MemberRowView: View {
    let member: MemberRow

    var body: some View {
        HStack(spacing: 10) {
            Text(Self.initials(member.title))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.phInk)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.phSky))
                .accessibilityHidden(true)
            Text(member.title)
                .foregroundStyle(Color.phInk)
                .lineLimit(1)
            Spacer(minLength: 8)
            if member.isLeader {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.phInk)
                    .accessibilityLabel(String(localized: "group.leader_icon", defaultValue: "Leader"))
                    .accessibilityIdentifier("groupDetail.leaderIcon")
            }
            if let note = member.note {
                Text(note)
                    .font(.caption2.weight(.semibold))
                    .tracking(0.7)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.phInk)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.phSky))
                    .accessibilityIdentifier("groupDetail.note")
            }
        }
    }

    /// Up to two initials from the display name, for the avatar.
    static func initials(_ name: String) -> String {
        String(name.split(separator: " ").compactMap(\.first).prefix(2)).uppercased()
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(detail: GroupDetail(
            groupId: "1", title: "Tuesday Night Group", description: "Study, conversation and dinner together.",
            meeting: "Tuesdays · 7:00 PM", location: "Lee home, North Park", leadersLine: "Leaders: Jordan Lee",
            membersTitle: "Members",
            members: [
                MemberRow(userId: "a", title: "Jordan Lee", note: nil, isLeader: true),
                MemberRow(userId: "b", title: "Maria Lopez", note: "You", isLeader: false),
            ]
        ))
    }
}
