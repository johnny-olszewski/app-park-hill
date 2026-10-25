package app.parkhill.screens.community

import androidx.compose.runtime.Composable
import app.parkhill.contract.CommunityGroupData

/** `community.group`: a group's detail, pushed from a group row; its title is the group's name. */
@Composable
fun CommunityGroupScreen(data: CommunityGroupData) {
    GroupDetailView(data)
}
