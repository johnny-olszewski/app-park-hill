import SwiftUI

/// One person: initials, name, an optional second line and the backend's
/// note, such as "Already a member". A shared component: the people picker
/// uses it, and the future directory will.
struct PersonRowView: View {
    let person: PersonRow
    var isChosen = false

    var body: some View {
        HStack(spacing: 10) {
            Text(MemberRowView.initials(person.title))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.phInk)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.phSky))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.title)
                    .foregroundStyle(person.selectable ? Color.phInk : Color.phInkMuted)
                    .lineLimit(1)
                if let subtitle = person.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.phInkMuted)
                }
            }
            Spacer(minLength: 8)
            if let note = person.note {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(Color.phInkMuted)
                    .accessibilityIdentifier("personRow.note")
            }
            if isChosen {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.phInk)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }
}
