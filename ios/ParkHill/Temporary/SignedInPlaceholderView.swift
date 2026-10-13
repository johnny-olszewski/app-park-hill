// TEMPORARY(EP-02): this file and the Temporary folder are deleted by IOS-008.
import SwiftUI

/// The only client-owned screen: shown while signed in until the tab shell
/// exists (specs/AUTH.md 6.2). Not backend driven; its text is bundled.
struct SignedInPlaceholderView: View {
    let user: AuthUser
    let signOut: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(String(localized: "placeholder.signed_in_as", defaultValue: "Signed in as"))
                    .foregroundStyle(Color.phInkMuted)
                Text(user.email ?? user.id)
                    .font(.phHeading)
                    .foregroundStyle(Color.phInk)
                    .accessibilityIdentifier("placeholder.user")
                Button(String(localized: "placeholder.sign_out", defaultValue: "Sign out"), role: .destructive, action: signOut)
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("placeholder.signOut")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.phSurface)
            .navigationTitle(String(localized: "placeholder.title", defaultValue: "Park Hill"))
        }
    }
}
