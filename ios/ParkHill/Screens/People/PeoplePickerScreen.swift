import SwiftUI

/// What the people picker has chosen and is showing (specs/COMMUNITY.md
/// 5.8): rows the backend marks not selectable cannot be chosen, and search
/// filters by name without dropping anyone already chosen.
struct PeoplePickerState: Equatable {
    let rows: [PersonRow]
    var query = ""
    private(set) var chosen: Set<String> = []

    /// Rows whose title contains the query, ignoring case and surrounding
    /// spaces; every row for an empty query.
    var visibleRows: [PersonRow] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return rows }
        return rows.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    /// The chosen people, in list order.
    var chosenRows: [PersonRow] { rows.filter { chosen.contains($0.userId) } }

    func isChosen(_ row: PersonRow) -> Bool { chosen.contains(row.userId) }

    /// Chooses `row`, or unchooses it when already chosen. Does nothing for
    /// a row that is not selectable.
    mutating func toggle(_ row: PersonRow) {
        guard row.selectable else { return }
        if chosen.remove(row.userId) == nil { chosen.insert(row.userId) }
    }
}

/// `people.picker`: everyone signed up, to choose people to add to a group.
/// Shown as a sheet; Add hands the chosen people back to whatever opened it,
/// Cancel hands back nothing.
struct PeoplePickerScreen: View {
    @State private var state: PeoplePickerState
    @Environment(\.sheetActions) private var sheet
    private let data: PeoplePickerData

    init(data: PeoplePickerData) {
        self.data = data
        _state = State(initialValue: PeoplePickerState(rows: data.rows))
    }

    var body: some View {
        List(state.visibleRows, id: \.userId) { person in
            Button {
                state.toggle(person)
            } label: {
                PersonRowView(person: person, isChosen: state.isChosen(person))
            }
            .disabled(!person.selectable)
            .accessibilityIdentifier("peoplePicker.row")
            .listRowBackground(Color.phSurfaceRaised)
        }
        .scrollContentBackground(.hidden)
        .background(Color.phSurface)
        .searchable(text: $state.query, placement: .navigationBarDrawer(displayMode: .always), prompt: data.searchPlaceholder)
        .navigationTitle(data.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            SwiftUI.ToolbarItem(placement: .cancellationAction) {
                Button(data.cancelLabel) { sheet.cancel() }
                    .accessibilityIdentifier("peoplePicker.cancel")
            }
            SwiftUI.ToolbarItem(placement: .confirmationAction) {
                Button(data.addLabel) { sheet.returnPeople(state.chosenRows) }
                    .disabled(state.chosenRows.isEmpty)
                    .accessibilityIdentifier("peoplePicker.add")
            }
        }
    }
}
