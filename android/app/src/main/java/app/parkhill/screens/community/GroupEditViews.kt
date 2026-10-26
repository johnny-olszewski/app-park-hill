package app.parkhill.screens.community

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconToggleButton
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.addPathNodes
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.parkhill.R
import app.parkhill.contract.ActionButton
import app.parkhill.contract.EditField
import app.parkhill.contract.EditFieldKind
import app.parkhill.design.ParkHill
import app.parkhill.design.brandFieldColors
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException
import java.time.format.FormatStyle

/** Edit, in the top app bar outside edit mode. */
@Composable
internal fun EditButton(label: String, onClick: () -> Unit) {
    TextButton(onClick = onClick, modifier = Modifier.testTag("groupDetail.edit")) {
        Text(label, color = ParkHill.colors.ink)
    }
}

/** Done, in place of the toolbar in edit mode: saves every staged change. */
@Composable
internal fun DoneButton(label: String, enabled: Boolean, onClick: () -> Unit) {
    TextButton(onClick = onClick, enabled = enabled, modifier = Modifier.testTag("groupDetail.done")) {
        Text(label, color = if (enabled) ParkHill.colors.ink else ParkHill.colors.inkMuted, fontWeight = FontWeight.SemiBold)
    }
}

/** Cancel, the navigation icon in edit mode: discards every staged change. */
@Composable
internal fun CancelButton(label: String, enabled: Boolean, onClick: () -> Unit) {
    IconButton(onClick = onClick, enabled = enabled, modifier = Modifier.testTag("groupDetail.cancel")) {
        Icon(Icons.Filled.Close, contentDescription = label)
    }
}

/** The details as inline fields in edit mode, each by its kind, with the backend's message under any field a save refused. */
internal fun LazyListScope.editFields(fields: List<EditField>, edit: GroupEditState) {
    items(fields, key = { "field.${it.id}" }) { field ->
        Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 6.dp)) {
            EditFieldControl(field, edit.values[field.id].orEmpty(), error = edit.fieldErrors[field.id]) { edit.setValue(field.id, it) }
            edit.fieldErrors[field.id]?.let { error ->
                Text(
                    error,
                    color = ParkHill.colors.danger,
                    fontSize = 12.sp,
                    modifier = Modifier.padding(start = 4.dp, top = 2.dp).testTag("groupDetail.fieldError.${field.id}"),
                )
            }
        }
    }
}

/** One field's Material control: a text field, a multiline field, a day dropdown from its options or a time picker. */
@Composable
private fun EditFieldControl(field: EditField, value: String, error: String?, onChange: (String) -> Unit) {
    val modifier = Modifier.fillMaxWidth().testTag("groupDetail.field.${field.id}")
    when (field.kind) {
        EditFieldKind.TEXT, EditFieldKind.MULTILINE -> OutlinedTextField(
            value = value,
            onValueChange = onChange,
            label = { Text(field.label) },
            singleLine = field.kind == EditFieldKind.TEXT,
            minLines = if (field.kind == EditFieldKind.MULTILINE) 3 else 1,
            isError = error != null,
            shape = ParkHill.shape,
            colors = brandFieldColors(),
            modifier = modifier,
        )
        EditFieldKind.DAY -> DayField(field, value, error != null, onChange, modifier)
        EditFieldKind.TIME -> TimeField(field, value, error != null, onChange, modifier)
    }
}

/** A day picked from the field's options (a Material exposed dropdown); the value is the option's. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DayField(field: EditField, value: String, isError: Boolean, onChange: (String) -> Unit, modifier: Modifier) {
    var open by remember { mutableStateOf(false) }
    val options = field.options.orEmpty()
    ExposedDropdownMenuBox(expanded = open, onExpandedChange = { open = it }) {
        OutlinedTextField(
            value = options.firstOrNull { it.value == value }?.label ?: value,
            onValueChange = {},
            readOnly = true,
            label = { Text(field.label) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = open) },
            isError = isError,
            shape = ParkHill.shape,
            colors = brandFieldColors(),
            modifier = modifier.menuAnchor(MenuAnchorType.PrimaryNotEditable),
        )
        ExposedDropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            options.forEach { option ->
                DropdownMenuItem(
                    text = { Text(option.label) },
                    onClick = {
                        onChange(option.value)
                        open = false
                    },
                    modifier = Modifier.testTag("groupDetail.field.${field.id}.${option.value}"),
                )
            }
        }
    }
}

/**
 * A time shown in the device's format, picked with the Material time picker
 * in a dialog; the value is "19:00". An unset or unreadable time opens at
 * 19:00, as on iOS.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TimeField(field: EditField, value: String, isError: Boolean, onChange: (String) -> Unit, modifier: Modifier) {
    var picking by remember { mutableStateOf(false) }
    val time = parseTime(value)
    Box(modifier) {
        OutlinedTextField(
            value = time?.format(DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT)) ?: value,
            onValueChange = {},
            readOnly = true,
            label = { Text(field.label) },
            isError = isError,
            shape = ParkHill.shape,
            colors = brandFieldColors(),
            modifier = Modifier.fillMaxWidth(),
        )
        // The read-only field opens the picker; it takes no typing.
        Box(Modifier.matchParentSize().clickable(role = Role.Button) { picking = true }.testTag("groupDetail.field.${field.id}.open"))
    }
    if (!picking) return
    val start = time ?: LocalTime.of(19, 0)
    val state = rememberTimePickerState(initialHour = start.hour, initialMinute = start.minute)
    AlertDialog(
        onDismissRequest = { picking = false },
        confirmButton = {
            TextButton(
                onClick = {
                    onChange("%02d:%02d".format(state.hour, state.minute))
                    picking = false
                },
                modifier = Modifier.testTag("groupDetail.timeConfirm"),
            ) {
                Text(stringResource(android.R.string.ok), color = ParkHill.colors.ink)
            }
        },
        dismissButton = {
            TextButton(onClick = { picking = false }) {
                Text(stringResource(android.R.string.cancel), color = ParkHill.colors.ink)
            }
        },
        title = { Text(field.label) },
        text = { TimePicker(state) },
        containerColor = ParkHill.colors.surface,
    )
}

/** "19:00" as a time, or null when it is not one. */
private fun parseTime(value: String): LocalTime? = try {
    LocalTime.parse(value)
} catch (_: DateTimeParseException) {
    null
}

/**
 * A member in edit mode, or a person added and not saved yet (muted): a
 * one-tap minus that stages the removal where the backend allows it (for a
 * pending person, drops them), and the leader icon as a toggle where it
 * allows that: filled for leaders, greyed for others. A refused save's
 * message shows on the row.
 */
@Composable
internal fun EditMemberRow(row: GroupEditState.Row, error: String?, remove: () -> Unit, toggleLeader: () -> Unit) {
    Column(
        Modifier.fillMaxWidth().padding(start = 4.dp, end = 8.dp, top = 2.dp, bottom = 2.dp)
            .testTag(if (row.isPending) "groupDetail.pendingRow" else "groupDetail.editRow"),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (row.canRemove) {
                IconButton(onClick = remove, modifier = Modifier.testTag("groupDetail.removeRow")) {
                    Icon(RemoveCircle, contentDescription = stringResource(R.string.group_remove_member), tint = ParkHill.colors.danger)
                }
            } else {
                Spacer(Modifier.width(48.dp))
            }
            Box(Modifier.size(32.dp).background(ParkHill.colors.sky, CircleShape), contentAlignment = Alignment.Center) {
                Text(initials(row.title), color = ParkHill.colors.ink, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
            }
            Spacer(Modifier.width(10.dp))
            Text(
                row.title,
                color = if (row.isPending) ParkHill.colors.inkMuted else ParkHill.colors.ink,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f),
            )
            if (row.canToggleLeader) {
                IconToggleButton(checked = row.isLeader, onCheckedChange = { toggleLeader() }, modifier = Modifier.testTag("groupDetail.leaderToggle")) {
                    Icon(
                        Icons.Filled.Star,
                        contentDescription = stringResource(R.string.group_leader_icon),
                        tint = if (row.isLeader) ParkHill.colors.ink else ParkHill.colors.inkMuted.copy(alpha = 0.35f),
                        modifier = Modifier.size(20.dp),
                    )
                }
            } else if (row.isLeader) {
                Icon(
                    Icons.Filled.Star,
                    contentDescription = stringResource(R.string.group_leader_icon),
                    tint = ParkHill.colors.ink,
                    modifier = Modifier.padding(horizontal = 8.dp).size(18.dp).testTag("groupDetail.leaderIcon"),
                )
            }
            row.note?.let { note -> Badge(note, Modifier.padding(start = 8.dp)) }
        }
        error?.let {
            Text(
                it,
                color = ParkHill.colors.danger,
                fontSize = 12.sp,
                modifier = Modifier.padding(start = 90.dp, bottom = 4.dp).testTag("groupDetail.rowError"),
            )
        }
    }
}

/** Add member, after the rows in edit mode: opens the people picker. */
@Composable
internal fun AddMemberButton(addMember: ActionButton, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable(role = Role.Button, onClick = onClick).padding(horizontal = 16.dp, vertical = 14.dp)
            .testTag("groupDetail.addMember"),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(Icons.Filled.Add, contentDescription = null, tint = ParkHill.colors.ink)
        Text(addMember.label, color = ParkHill.colors.ink, fontWeight = FontWeight.SemiBold)
    }
}

/** Material's "remove circle" symbol, which the core icon set leaves out. */
private val RemoveCircle: ImageVector = ImageVector.Builder("RemoveCircle", 24.dp, 24.dp, 24f, 24f)
    .addPath(
        pathData = addPathNodes("M12,2C6.48,2 2,6.48 2,12s4.48,10 10,10 10,-4.48 10,-10S17.52,2 12,2zM17,13H7v-2h10v2z"),
        fill = SolidColor(Color.Black),
    )
    .build()
