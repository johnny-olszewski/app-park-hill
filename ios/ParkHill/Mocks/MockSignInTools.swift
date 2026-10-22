import Observation
import SwiftUI

/// The mock menu's view of `MockSignInScenario`: observable, so the pill and
/// menu update as choices change, and written through to the shared scenario
/// the mock auth service reads.
@MainActor
@Observable
final class MockSignInChoices {
    let personas: [MockPersona]
    var persona: String {
        didSet { scenario.persona = persona }
    }
    var result: MockSignInResult {
        didSet { scenario.result = result }
    }
    @ObservationIgnored private let scenario: MockSignInScenario

    init(scenario: MockSignInScenario, personas: [MockPersona]) {
        self.scenario = scenario
        self.personas = personas
        persona = scenario.persona
        result = scenario.result
    }

    /// Shown on the pill and at the top of the menu while a failure is armed.
    var warning: String? {
        result == .success ? nil : "Next sign-in will fail: \(result.title)"
    }
}

/// The Mock build's tools (specs/AUTH.md 5.4): who the next sign-in signs in
/// as and what it returns, on the sign-in screen; switching persona while
/// signed in, everywhere.
@MainActor
enum MockSignInTools {
    static let signInScreenKey = ScreenKey.authSignIn

    static func register(in registry: inout DevToolRegistry, choices: MockSignInChoices, session: SessionTracker, auth: MockAuthService) {
        registry.register(DevTool(id: "mock.signIn.persona", title: "Sign in as") {
            PersonaRows(personas: choices.personas, selected: choices.persona, identifier: "mockSignIn.persona") {
                choices.persona = $0
            }
        }, forScreen: signInScreenKey)

        registry.register(DevTool(id: "mock.signIn.result", title: "Next sign-in", warning: { choices.warning }) {
            ForEach(MockSignInResult.allCases) { result in
                CheckmarkRow(isSelected: choices.result == result) {
                    choices.result = result
                } label: {
                    Text(result.title).foregroundStyle(Color.phInk)
                }
                .accessibilityIdentifier("mockSignIn.result.\(result.rawValue)")
            }
        }, forScreen: signInScreenKey)

        registry.registerAppTool(DevTool(id: "mock.switchPersona", title: "Switch persona") {
            if let user = session.user {
                PersonaRows(personas: choices.personas, selected: user.id, identifier: "mockPersona") {
                    auth.signIn(persona: $0)
                }
            } else {
                Text("Not signed in").foregroundStyle(Color.phInkMuted)
            }
        })
    }
}

/// One row per persona, with a checkmark on the selected one.
private struct PersonaRows: View {
    let personas: [MockPersona]
    let selected: String?
    let identifier: String
    let select: (String) -> Void

    var body: some View {
        ForEach(personas) { persona in
            CheckmarkRow(isSelected: persona.id == selected) {
                select(persona.id)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(persona.displayName).foregroundStyle(Color.phInk)
                    Text(persona.description).font(.caption).foregroundStyle(Color.phInkMuted)
                }
            }
            .accessibilityIdentifier("\(identifier).\(persona.id)")
        }
    }
}

/// A list row that selects on tap and shows a checkmark when selected.
private struct CheckmarkRow<Label: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let label: Label

    var body: some View {
        Button(action: action) {
            HStack {
                label
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark").foregroundStyle(Color.phInk)
                }
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
