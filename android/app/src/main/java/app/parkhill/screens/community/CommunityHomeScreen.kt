package app.parkhill.screens.community

import androidx.compose.runtime.Composable
import app.parkhill.contract.CommunityHomeData
import app.parkhill.contract.EmptyState
import app.parkhill.contract.GroupDetail
import app.parkhill.contract.GroupList

/** What Community home shows, inferred from which part of its data is present, checked in this order (specs/COMMUNITY.md 4.1). */
sealed interface CommunityHomeState {
    data class Group(val detail: GroupDetail) : CommunityHomeState
    data class MyGroups(val list: GroupList) : CommunityHomeState
    data class Empty(val empty: EmptyState) : CommunityHomeState

    companion object {
        /** Null when none of the parts is present: the data is unusable. */
        fun of(data: CommunityHomeData): CommunityHomeState? = when {
            data.group != null -> Group(data.group)
            data.myGroups != null -> MyGroups(data.myGroups)
            data.empty != null -> Empty(data.empty)
            else -> null
        }
    }
}

/**
 * The Community tab's root: the person's one group, their groups, or an empty
 * message with no buttons. The tab title stays the one get_tabs sends.
 */
@Composable
fun CommunityHomeScreen(data: CommunityHomeData) {
    when (val state = CommunityHomeState.of(data)) {
        is CommunityHomeState.Group -> GroupDetailView(state.detail)
        is CommunityHomeState.MyGroups -> GroupListView(state.list)
        is CommunityHomeState.Empty -> EmptyStateView(state.empty)
        // Never resolved: the registry refuses unusable data.
        null -> Unit
    }
}
