import SwiftUI

/// Shows a `ScreenModel`: loading, the screen with pull to refresh, or the
/// error screen with retry.
struct ScreenHostView: View {
    let model: ScreenModel

    var body: some View {
        switch model.state {
        case .loading:
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.phSurface)
                .accessibilityIdentifier("screen.loading")
        case .screen(let screen):
            screen.view
                .refreshable { await model.load() }
        case .error:
            ScreenErrorView {
                Task { await model.retry() }
            }
        }
    }
}

/// A backend screen that could not be fetched and has no cached copy.
/// Client-owned, so its text is bundled.
struct ScreenErrorView: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(String(localized: "screen_error.title", defaultValue: "We couldn't load this."))
                .font(.phHeading)
                .foregroundStyle(Color.phInk)
            Text(String(localized: "screen_error.message", defaultValue: "Check your connection and try again."))
                .foregroundStyle(Color.phInk)
            Button(String(localized: "screen_error.retry", defaultValue: "Try again"), action: retry)
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("screenError.retry")
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.phSurface)
    }
}

#Preview {
    ScreenErrorView {}
}
