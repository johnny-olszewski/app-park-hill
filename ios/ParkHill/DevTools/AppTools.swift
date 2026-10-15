import Observation
import SwiftUI
import UIKit

/// The tools on every screen: what this build talks to, what the current
/// screen received, clearing cached data, and signing out.
@MainActor
enum AppTools {
    static func all(environment: AppEnvironment, tracker: CurrentScreenTracker, session: SessionTracker, auth: any AuthService) -> [DevTool] {
        [
            DevTool(id: "app.build", title: "Build") {
                LabeledContent("Environment", value: environment.name)
                LabeledContent("Backend", value: environment.backend?.url.absoluteString ?? "No network")
                    .accessibilityIdentifier("devTools.build.backend")
            },
            DevTool(id: "app.screen", title: "Screen") {
                NavigationLink {
                    CurrentScreenPage(envelope: tracker.current)
                } label: {
                    LabeledContent("Current screen", value: tracker.current?.key ?? "None")
                }
                .accessibilityIdentifier("devTools.currentScreen")
            },
            DevTool(id: "app.data", title: "Data") {
                ClearCachedDataButton(directory: CacheDirectory.url)
            },
            DevTool(id: "app.session", title: "Session") {
                if session.isSignedIn {
                    SignOutButton(auth: auth)
                } else {
                    Text("Not signed in").foregroundStyle(Color.phInkMuted)
                }
            },
        ]
    }

    /// Screen data as indented JSON with sorted keys, for reading and copying.
    static func formattedJSON(_ value: JSONValue) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(value) else { return "Unreadable" }
        return String(decoding: data, as: UTF8.self)
    }
}

/// Who is signed in, if anyone, followed from the auth service's state.
@MainActor
@Observable
final class SessionTracker {
    private(set) var user: AuthUser?
    @ObservationIgnored private var observation: Task<Void, Never>?

    var isSignedIn: Bool { user != nil }

    init(auth: any AuthService) {
        let changes = auth.stateChanges()
        observation = Task { [weak self] in
            for await state in changes {
                if case .signedIn(let user) = state {
                    self?.user = user
                } else {
                    self?.user = nil
                }
            }
        }
    }

    deinit {
        observation?.cancel()
    }
}

/// The current screen's key and data, copyable.
private struct CurrentScreenPage: View {
    let envelope: ScreenEnvelope?
    @State private var copied = false

    var body: some View {
        List {
            if let envelope {
                let json = AppTools.formattedJSON(envelope.data)
                Section("Key") {
                    Text(envelope.key)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .accessibilityIdentifier("devTools.currentScreen.key")
                }
                Section("Data") {
                    Text(json)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .accessibilityIdentifier("devTools.currentScreen.data")
                    Button(copied ? "Copied" : "Copy data") {
                        UIPasteboard.general.string = json
                        copied = true
                    }
                }
            } else {
                Text("No backend-driven screen is showing.").foregroundStyle(Color.phInkMuted)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.phSurface)
        .navigationTitle("Current screen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Deletes everything the app caches, after a confirmation. The session and
/// the screen showing are untouched.
private struct ClearCachedDataButton: View {
    let directory: URL
    @State private var isConfirming = false
    @State private var cleared = false

    var body: some View {
        Button(cleared ? "Cached data cleared" : "Clear cached data") {
            isConfirming = true
        }
        .disabled(cleared)
        .accessibilityIdentifier("devTools.clearCache")
        .confirmationDialog("Clear cached data?", isPresented: $isConfirming, titleVisibility: .visible) {
            Button("Clear cached data", role: .destructive) {
                try? FileManager.default.removeItem(at: directory)
                cleared = true
            }
        } message: {
            Text("Cached screens are deleted. The next launch fetches everything again.")
        }
    }
}

/// Signs out and closes the menu, revealing sign-in.
private struct SignOutButton: View {
    let auth: any AuthService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button("Sign out", role: .destructive) {
            dismiss()
            Task { await auth.signOut() }
        }
        .accessibilityIdentifier("devTools.signOut")
    }
}
