import SwiftUI

/// `auth.sign_in` data (specs/AUTH.md 5.3). Only the title for now; the rest
/// of the screen arrives in IOS-006.
struct SignInScreenData: Decodable, Equatable {
    let title: String
}

/// `auth.sign_in`: minimal until IOS-006, rendering only its title.
struct SignInScreen: View {
    let data: SignInScreenData

    var body: some View {
        Text(data.title)
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SignInScreen(data: SignInScreenData(title: "Sign in"))
}
