import SwiftUI

/// `home.root` data: empty until Home has content.
struct HomeRootData: Decodable {}

/// The Home tab's root screen. Empty for now (EP-02).
struct HomeRootScreen: View {
    let data: HomeRootData

    var body: some View {
        Color.phSurface.ignoresSafeArea()
    }
}
