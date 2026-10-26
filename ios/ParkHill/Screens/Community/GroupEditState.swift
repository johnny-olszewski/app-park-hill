import Foundation

/// Group detail's edit mode (specs/COMMUNITY.md 5.3, 5.4): every change is
/// staged here, with no confirmations, until Done sends them all as one
/// save batch; Cancel drops this. Built from the detail as it was when Edit
/// was tapped, so a refresh underneath keeps the staged changes.
struct GroupEditState: Equatable {
    let original: GroupDetail
    /// Each edit field's value now, by field id.
    var values: [String: String]
    /// People chosen in the picker, shown as pending rows, in the order added.
    private(set) var added: [PersonRow] = []
    private(set) var removed: Set<String> = []
    /// Members whose leadership is staged to change, to the state it will have.
    private(set) var leaders: [String: Bool] = [:]
    /// The backend's messages from a failed save, by field id.
    var fieldErrors: [String: String] = [:]
    /// The backend's messages from a failed save, by user id.
    var rowErrors: [String: String] = [:]

    init(_ detail: GroupDetail) {
        original = detail
        values = Dictionary(uniqueKeysWithValues: (detail.editFields ?? []).map { ($0.id, $0.value) })
    }

    /// A row in edit mode: a member, or a person added and not saved yet.
    struct Row: Equatable, Identifiable {
        let id: String
        let title: String
        let note: String?
        let isLeader: Bool
        let isPending: Bool
        let canRemove: Bool
        let canToggleLeader: Bool
    }

    /// The members still staged to stay, then the pending people.
    var rows: [Row] {
        original.members.filter { !removed.contains($0.userId) }.map { member in
            Row(
                id: member.userId, title: member.title, note: member.note, isLeader: isLeader(member),
                isPending: false, canRemove: member.remove != nil, canToggleLeader: member.toggleLeader == true
            )
        } + added.map { person in
            Row(id: person.userId, title: person.title, note: nil, isLeader: false, isPending: true, canRemove: true, canToggleLeader: false)
        }
    }

    func isLeader(_ member: MemberRow) -> Bool { leaders[member.userId] ?? member.isLeader }

    /// Adds people from the picker, once each, leaving out current members.
    mutating func add(_ people: [PersonRow]) {
        let present = Set(original.members.map(\.userId)).union(added.map(\.userId))
        for person in people where !present.contains(person.userId) {
            added.append(person)
        }
    }

    /// Stages removing the row: a pending person is just dropped.
    mutating func remove(_ userID: String) {
        if let index = added.firstIndex(where: { $0.userId == userID }) {
            added.remove(at: index)
        } else if original.members.contains(where: { $0.userId == userID && $0.remove != nil }) {
            removed.insert(userID)
            leaders[userID] = nil
        }
    }

    /// Stages making the member a leader, or removing their leadership;
    /// toggling back unstages it.
    mutating func toggleLeader(_ userID: String) {
        guard let member = original.members.first(where: { $0.userId == userID }), member.toggleLeader == true else { return }
        let next = !isLeader(member)
        leaders[userID] = next == member.isLeader ? nil : next
    }

    /// The save batch: only fields whose value changed, and every staged
    /// change to people (specs/COMMUNITY.md 5.4).
    var batch: JSONValue {
        let changed = (original.editFields ?? []).filter { values[$0.id] != $0.value }
        let ids = { (ids: [String]) in JSONValue.array(ids.sorted().map(JSONValue.string)) }
        return .object([
            "fields": .object(Dictionary(uniqueKeysWithValues: changed.map { ($0.id, JSONValue.string(values[$0.id] ?? "")) })),
            "add": .array(added.map { .string($0.userId) }),
            "remove": ids(Array(removed)),
            "make_leader": ids(leaders.filter { $0.value }.map(\.key)),
            "remove_leader": ids(leaders.filter { !$0.value }.map(\.key)),
        ])
    }

    /// Keeps the staged changes and shows a failed save's problems in place.
    mutating func show(_ result: SaveResult) {
        fieldErrors = Self.messages(result.fieldErrors)
        rowErrors = Self.messages(result.rowErrors)
    }

    private static func messages(_ value: JSONValue?) -> [String: String] {
        value?.objectValue.compactMapValues { if case .string(let message) = $0 { message } else { nil } } ?? [:]
    }
}
