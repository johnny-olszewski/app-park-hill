import SwiftUI

/// Shown when nothing usable can be displayed at launch. Client-owned, so its
/// text is bundled: the backend cannot be reached to supply it.
struct LaunchErrorScreen: View {
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(
                String(localized: "launch_error.title", defaultValue: "Can't connect"),
                systemImage: "wifi.exclamationmark"
            )
        } description: {
            Text(String(localized: "launch_error.message", defaultValue: "Check your connection and try again."))
        } actions: {
            Button(String(localized: "launch_error.retry", defaultValue: "Try again"), action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    LaunchErrorScreen {}
}
