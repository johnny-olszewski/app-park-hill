import SwiftUI

/// A group's details and members (specs/COMMUNITY.md 5.1 to 5.4): swipe to
/// remove on rows the backend sends `remove` for, a Leave footer when it
/// sends `leave`, and edit mode when it sends `edit`. A client component
/// shared by `community.group` and Community home's one group; every word
/// comes from the data.
struct GroupDetailView: View {
    let detail: GroupDetail
    @Environment(\.screenActions) private var actions
    /// Edit mode's staged changes; nil outside edit mode.
    @State private var editing: GroupEditState?
    @State private var isSaving = false

    var body: some View {
        List {
            if let editing {
                EditDetailsSection(fields: detail.editFields ?? [], edit: binding(editing))
            } else {
                DetailsSection(detail: detail)
            }

            Section {
                if let editing {
                    ForEach(editing.rows) { row in
                        EditMemberRowView(
                            row: row,
                            error: editing.rowErrors[row.id],
                            toggleLeader: { self.editing?.toggleLeader(row.id) }
                        )
                        .deleteDisabled(!row.canRemove)
                    }
                    .onDelete { offsets in
                        for row in offsets.map({ editing.rows[$0] }) { self.editing?.remove(row.id) }
                    }
                    if let addMember = detail.addMember {
                        Button {
                            actions.open(addMember.action) { people in self.editing?.add(people) }
                        } label: {
                            Label(addMember.label, systemImage: "plus")
                        }
                        .accessibilityIdentifier("groupDetail.addMember")
                    }
                } else {
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
                }
            } header: {
                Text(detail.membersTitle)
                    .brandLabel()
                    .accessibilityIdentifier("groupDetail.membersTitle")
            }
            .listRowBackground(Color.phSurfaceRaised)

            if let leave = detail.leave, editing == nil {
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
        .environment(\.editMode, .constant(editing == nil ? .inactive : .active))
        .refreshable(isEnabled: editing == nil)
        .toolbar { editToolbar }
        .navigationBarBackButtonHidden(editing != nil)
    }

    /// Edit, or Cancel and Done while editing, with the backend's labels.
    @ToolbarContentBuilder
    private var editToolbar: some ToolbarContent {
        if let labels = detail.edit {
            if editing == nil {
                SwiftUI.ToolbarItem(placement: .primaryAction) {
                    Button(labels.editLabel) { editing = GroupEditState(detail) }
                        .accessibilityIdentifier("groupDetail.edit")
                }
            } else {
                SwiftUI.ToolbarItem(placement: .cancellationAction) {
                    Button(labels.cancelLabel) { editing = nil }
                        .disabled(isSaving)
                        .accessibilityIdentifier("groupDetail.cancel")
                }
                SwiftUI.ToolbarItem(placement: .confirmationAction) {
                    Button(labels.doneLabel) { Task { await save() } }
                        .disabled(isSaving)
                        .accessibilityIdentifier("groupDetail.done")
                }
            }
        }
    }

    /// The staged changes for the fields. A write after Cancel, such as a
    /// field ending its editing, does not bring edit mode back.
    private func binding(_ value: GroupEditState) -> Binding<GroupEditState> {
        Binding(get: { editing ?? value }, set: { if editing != nil { editing = $0 } })
    }

    /// Done: one save with every staged change. `ok` leaves edit mode (the
    /// screen refreshes); otherwise edit mode stays with each problem shown.
    private func save() async {
        guard let edit = editing, let save = detail.save else { return }
        isSaving = true
        defer { isSaving = false }
        let body = await actions.submit(save, adding: ["p_batch": edit.batch]) { body in
            body.objectValue["ok"] == .bool(true)
        }
        guard let body, let result = try? JSONDecoder().decode(SaveResult.self, from: JSONEncoder().encode(body)) else { return }
        if result.ok {
            editing = nil
        } else {
            editing?.show(result)
        }
    }
}

/// The details as the backend formats them, outside edit mode.
private struct DetailsSection: View {
    let detail: GroupDetail

    var body: some View {
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
    }
}

/// The details as inline fields in edit mode, each by its kind, with the
/// backend's message under any field a save refused.
private struct EditDetailsSection: View {
    let fields: [EditField]
    @Binding var edit: GroupEditState

    var body: some View {
        Section {
            ForEach(fields, id: \.id) { field in
                VStack(alignment: .leading, spacing: 4) {
                    control(for: field)
                    if let error = edit.fieldErrors[field.id] {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color.phDanger)
                            .accessibilityIdentifier("groupDetail.fieldError.\(field.id)")
                    }
                }
            }
        }
        .listRowBackground(Color.phSurfaceRaised)
    }

    @ViewBuilder
    private func control(for field: EditField) -> some View {
        let value = Binding(get: { edit.values[field.id] ?? "" }, set: { edit.values[field.id] = $0 })
        switch field.kind {
        case .text:
            LabeledContent(field.label) {
                TextField(field.label, text: value).multilineTextAlignment(.trailing)
            }
            .accessibilityIdentifier("groupDetail.field.\(field.id)")
        case .multiline:
            VStack(alignment: .leading) {
                Text(field.label).font(.footnote).foregroundStyle(Color.phInkMuted)
                TextField(field.label, text: value, axis: .vertical).lineLimit(2...6)
            }
            .accessibilityIdentifier("groupDetail.field.\(field.id)")
        case .day:
            Picker(field.label, selection: value) {
                ForEach(field.options ?? [], id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .accessibilityIdentifier("groupDetail.field.\(field.id)")
        case .time:
            DatePicker(field.label, selection: Binding(get: { Self.date(value.wrappedValue) }, set: { value.wrappedValue = Self.time($0) }), displayedComponents: .hourAndMinute)
                .accessibilityIdentifier("groupDetail.field.\(field.id)")
        }
    }

    private static let calendar = Calendar(identifier: .gregorian)

    /// "19:00" as a date today; an unset time shows as 19:00.
    static func date(_ time: String) -> Date {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        return calendar.date(bySettingHour: parts.first ?? 19, minute: parts.count > 1 ? parts[1] : 0, second: 0, of: .now) ?? .now
    }

    /// A date's time as "19:00".
    static func time(_ date: Date) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }
}

/// A member in edit mode: the leader icon is a toggle where the backend
/// allows it, and a refused save's message shows on the row.
private struct EditMemberRowView: View {
    let row: GroupEditState.Row
    let error: String?
    let toggleLeader: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Text(MemberRowView.initials(row.title))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.phInk)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.phSky))
                    .accessibilityHidden(true)
                Text(row.title)
                    .foregroundStyle(row.isPending ? Color.phInkMuted : Color.phInk)
                    .lineLimit(1)
                    .accessibilityIdentifier(row.isPending ? "groupDetail.pendingRow" : "groupDetail.editRow")
                Spacer(minLength: 8)
                if row.canToggleLeader {
                    Button(action: toggleLeader) {
                        Image(systemName: row.isLeader ? "star.fill" : "star")
                            .foregroundStyle(row.isLeader ? Color.phInk : Color.phInkMuted)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(String(localized: "group.leader_icon", defaultValue: "Leader"))
                    .accessibilityValue(row.isLeader ? Text(String(localized: "group.leader_on", defaultValue: "On")) : Text(String(localized: "group.leader_off", defaultValue: "Off")))
                    .accessibilityIdentifier("groupDetail.leaderToggle")
                } else if row.isLeader {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.phInk)
                        .accessibilityLabel(String(localized: "group.leader_icon", defaultValue: "Leader"))
                        .accessibilityIdentifier("groupDetail.leaderIcon")
                }
                if let note = row.note {
                    Text(note)
                        .font(.caption2.weight(.semibold))
                        .tracking(0.7)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.phInk)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.phSky))
                }
            }
            if let error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Color.phDanger)
                    .accessibilityIdentifier("groupDetail.rowError")
            }
        }
    }
}

private extension View {
    /// Pull to refresh only when enabled: in edit mode it does nothing, so a
    /// refresh does not land under staged changes. The screen's own refresh
    /// is replaced, since it cannot be removed.
    @ViewBuilder
    func refreshable(isEnabled: Bool) -> some View {
        if isEnabled { self } else { self.refreshable {} }
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
