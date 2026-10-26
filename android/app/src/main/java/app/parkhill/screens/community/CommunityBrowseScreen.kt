package app.parkhill.screens.community

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.DockedSearchBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.SearchBarDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import app.parkhill.R
import app.parkhill.contract.CommunityBrowseData
import app.parkhill.contract.GroupRow
import app.parkhill.design.ParkHill
import app.parkhill.navigation.LocalScreenActions

/** The rows whose title contains `query`, ignoring case and surrounding spaces, in order; every row for a blank query. */
fun filterGroupRows(rows: List<GroupRow>, query: String): List<GroupRow> {
    val text = query.trim()
    if (text.isEmpty()) return rows
    return rows.filter { it.title.contains(text, ignoreCase = true) }
}

/**
 * Browse all groups (specs/COMMUNITY.md 4.2): a Material search field over
 * every group, filtering the loaded rows by title as you type, on the
 * device. The title is the screen's, in the bar that presents it. Tapping a
 * row ends the search first (clears it and drops focus), so back from a group
 * shows every group, matching iOS; it also starts empty each time the screen
 * is presented.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CommunityBrowseScreen(data: CommunityBrowseData) {
    var query by rememberSaveable { mutableStateOf("") }
    val rows = remember(data.rows, query) { filterGroupRows(data.rows, query) }
    val keyboard = LocalSoftwareKeyboardController.current
    val focus = LocalFocusManager.current
    val actions = LocalScreenActions.current
    val endingSearch = remember(actions) {
        actions.onPerform {
            query = ""
            focus.clearFocus()
        }
    }
    Column(Modifier.fillMaxSize().background(ParkHill.colors.surface)) {
        DockedSearchBar(
            inputField = {
                SearchBarDefaults.InputField(
                    query = query,
                    onQueryChange = { query = it },
                    onSearch = { keyboard?.hide() },
                    expanded = false,
                    onExpandedChange = {},
                    placeholder = { Text(data.searchPlaceholder) },
                    leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                    trailingIcon = if (query.isEmpty()) null else {
                        {
                            IconButton(onClick = { query = "" }, modifier = Modifier.testTag("browse.clear")) {
                                Icon(Icons.Filled.Close, contentDescription = stringResource(R.string.search_clear))
                            }
                        }
                    },
                    modifier = Modifier.testTag("browse.search"),
                )
            },
            expanded = false,
            onExpandedChange = {},
            colors = SearchBarDefaults.colors(containerColor = ParkHill.colors.surfaceSunken),
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        ) {}
        CompositionLocalProvider(LocalScreenActions provides endingSearch) {
            GroupRows(rows, Modifier.weight(1f))
        }
    }
}
