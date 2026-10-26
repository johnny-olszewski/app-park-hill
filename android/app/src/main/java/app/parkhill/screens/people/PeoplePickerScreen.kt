package app.parkhill.screens.people

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.selection.toggleable
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.DockedSearchBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.SearchBarDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.parkhill.R
import app.parkhill.contract.PeoplePickerData
import app.parkhill.contract.PersonRow
import app.parkhill.design.ParkHill
import app.parkhill.navigation.LocalSheetActions

/**
 * What the people picker has chosen and is showing (specs/COMMUNITY.md 5.8):
 * rows the backend marks not selectable cannot be chosen, and search filters
 * by name without dropping anyone already chosen. Snapshot state.
 */
class PeoplePickerState(val rows: List<PersonRow>) {
    var query: String by mutableStateOf("")

    private var chosen: Set<String> by mutableStateOf(emptySet())

    /** Rows whose title contains the query, ignoring case and surrounding spaces; every row for a blank query. */
    val visibleRows: List<PersonRow>
        get() {
            val text = query.trim()
            if (text.isEmpty()) return rows
            return rows.filter { it.title.contains(text, ignoreCase = true) }
        }

    /** The chosen people, in list order. */
    val chosenRows: List<PersonRow> get() = rows.filter { it.userId in chosen }

    fun isChosen(row: PersonRow): Boolean = row.userId in chosen

    /** Chooses `row`, or unchooses it when already chosen. Does nothing for a row that is not selectable. */
    fun toggle(row: PersonRow) {
        if (!row.selectable) return
        chosen = if (row.userId in chosen) chosen - row.userId else chosen + row.userId
    }
}

/**
 * `people.picker`: everyone signed up, to choose people to add to a group.
 * Shown as a sheet, under its own header: Cancel hands back nothing, Add
 * (once someone is chosen) hands the chosen people back to whatever opened
 * it. A Material search field filters by name as you type; each person who
 * can be chosen has a checkbox.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PeoplePickerScreen(data: PeoplePickerData) {
    val state = remember(data.rows) { PeoplePickerState(data.rows) }
    val sheet = LocalSheetActions.current
    val keyboard = LocalSoftwareKeyboardController.current
    Column(Modifier.fillMaxSize().background(ParkHill.colors.surface)) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = sheet.cancel, modifier = Modifier.testTag("picker.cancel")) {
                Text(data.cancelLabel, color = ParkHill.colors.ink)
            }
            Text(
                data.title,
                style = ParkHill.heading.copy(fontSize = 20.sp),
                color = ParkHill.colors.ink,
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f).testTag("picker.title"),
            )
            TextButton(
                onClick = { sheet.returnPeople(state.chosenRows) },
                enabled = state.chosenRows.isNotEmpty(),
                modifier = Modifier.testTag("picker.add"),
            ) {
                Text(data.addLabel, color = if (state.chosenRows.isNotEmpty()) ParkHill.colors.ink else ParkHill.colors.inkMuted)
            }
        }
        DockedSearchBar(
            inputField = {
                SearchBarDefaults.InputField(
                    query = state.query,
                    onQueryChange = { state.query = it },
                    onSearch = { keyboard?.hide() },
                    expanded = false,
                    onExpandedChange = {},
                    placeholder = { Text(data.searchPlaceholder) },
                    leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                    trailingIcon = if (state.query.isEmpty()) null else {
                        {
                            IconButton(onClick = { state.query = "" }, modifier = Modifier.testTag("picker.clear")) {
                                Icon(Icons.Filled.Close, contentDescription = stringResource(R.string.search_clear))
                            }
                        }
                    },
                    modifier = Modifier.testTag("picker.search"),
                )
            },
            expanded = false,
            onExpandedChange = {},
            colors = SearchBarDefaults.colors(containerColor = ParkHill.colors.surfaceSunken),
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        ) {}
        LazyColumn(Modifier.weight(1f).testTag("picker.rows")) {
            items(state.visibleRows, key = { it.userId }) { person ->
                PickerRow(person, chosen = state.isChosen(person)) { state.toggle(person) }
                HorizontalDivider(color = ParkHill.colors.line, modifier = Modifier.padding(start = 58.dp))
            }
        }
    }
}

/** A person with a checkbox, the whole row toggling it; a person who cannot be chosen shows their note and does nothing. */
@Composable
private fun PickerRow(person: PersonRow, chosen: Boolean, toggle: () -> Unit) {
    if (!person.selectable) {
        PersonRowView(person, Modifier.testTag("picker.row"))
        return
    }
    PersonRowView(
        person,
        Modifier.toggleable(value = chosen, role = Role.Checkbox, onValueChange = { toggle() }).testTag("picker.row"),
    ) {
        Checkbox(
            checked = chosen,
            onCheckedChange = null,
            colors = CheckboxDefaults.colors(checkedColor = ParkHill.colors.ink, checkmarkColor = ParkHill.colors.surface),
        )
    }
}
