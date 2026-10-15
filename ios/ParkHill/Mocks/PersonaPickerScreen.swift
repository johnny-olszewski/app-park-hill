import Foundation
import SwiftUI

/// `auth.sign_in.mock` data (specs/AUTH.md 5.4). Mock only: the real backend
/// never returns this key.
struct PersonaPickerData: Codable, Equatable {
    struct Persona: Codable, Equatable, Identifiable {
        let id: String
        let displayName: String
        let description: String

        enum CodingKeys: String, CodingKey {
            case id
            case displayName = "display_name"
            case description
        }
    }

    let title: String
    let personas: [Persona]
}

extension PersonaPickerData {
    static let screenKey = "auth.sign_in.mock"

    /// The picker for the active personas in the bundled
    /// `contract/seed/dataset.json`.
    static func fromDataset(at url: URL) throws -> PersonaPickerData {
        struct Dataset: Decodable {
            struct Persona: Decodable {
                let id: String
                let display_name: String
                let description: String
                let state: String
            }
            let personas: [Persona]
        }
        let dataset = try JSONDecoder().decode(Dataset.self, from: Data(contentsOf: url))
        return PersonaPickerData(
            title: "Mock sign in",
            personas: dataset.personas
                .filter { $0.state == "active" }
                .map { Persona(id: $0.id, displayName: $0.display_name, description: $0.description) }
        )
    }

    static var bundledDatasetURL: URL {
        guard let url = Bundle.main.url(forResource: "seed/dataset", withExtension: "json") else {
            preconditionFailure("contract/seed/dataset.json is not bundled in this configuration")
        }
        return url
    }

    var envelope: ScreenEnvelope {
        let json = try! JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(self))
        return ScreenEnvelope(key: Self.screenKey, data: json)
    }
}

/// `auth.sign_in.mock`: lists personas; tapping one signs in as it with no
/// network.
struct PersonaPickerScreen: View {
    let data: PersonaPickerData
    let auth: MockAuthService

    var body: some View {
        NavigationStack {
            List(data.personas) { persona in
                Button {
                    auth.signIn(persona: persona.id)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(persona.displayName)
                                .foregroundStyle(Color.phInk)
                            Text(persona.description)
                                .font(.caption)
                                .foregroundStyle(Color.phInkMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.phInkMuted)
                    }
                }
                .listRowBackground(Color.phSurfaceRaised)
                .accessibilityIdentifier("personaPicker.\(persona.id)")
            }
            .scrollContentBackground(.hidden)
            .background(Color.phSurface)
            .navigationTitle(data.title)
        }
    }
}
