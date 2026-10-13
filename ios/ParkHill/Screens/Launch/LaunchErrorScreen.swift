import SwiftUI

/// Shown when nothing usable can be displayed at launch. Client-owned, so its
/// text is bundled: the backend cannot be reached to supply it.
struct LaunchErrorScreen: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(String(localized: "launch_error.title", defaultValue: "We can't reach Park Hill right now."))
                .font(.phHeading)
                .foregroundStyle(Color.phInk)
            Text(String(localized: "launch_error.message", defaultValue: "Check your connection and try again."))
                .foregroundStyle(Color.phInk)
            Button(String(localized: "launch_error.retry", defaultValue: "Try again"), action: retry)
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("launchError.retry")
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.phSurface)
    }
}

#Preview {
    LaunchErrorScreen {}
}
