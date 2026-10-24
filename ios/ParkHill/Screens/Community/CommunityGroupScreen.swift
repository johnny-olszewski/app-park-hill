import SwiftUI

/// `community.group`: a group's detail, pushed from a group row, titled with
/// the group's name.
struct CommunityGroupScreen: View {
    let data: CommunityGroupData

    var body: some View {
        GroupDetailView(detail: data)
            .navigationTitle(data.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}
