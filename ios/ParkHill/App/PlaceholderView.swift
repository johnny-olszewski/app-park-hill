import SwiftUI

/// Blank launch view until the root coordinator replaces it (IOS-003).
struct PlaceholderView: View {
    var body: some View {
        Color(.systemBackground)
            .ignoresSafeArea()
    }
}

#Preview {
    PlaceholderView()
}
