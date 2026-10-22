import SwiftUI

/// `community.home` data: empty until EP-03 adds groups.
struct CommunityHomeData: Decodable {}

/// The Community tab's root screen. Empty for now (EP-02).
struct CommunityHomeScreen: View {
    let data: CommunityHomeData

    var body: some View {
        Color.phSurface.ignoresSafeArea()
    }
}
