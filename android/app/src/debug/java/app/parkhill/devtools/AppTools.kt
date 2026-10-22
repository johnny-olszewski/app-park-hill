package app.parkhill.devtools

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.parkhill.design.ParkHill
import app.parkhill.environment.AppEnvironment
import app.parkhill.services.auth.AuthService
import app.parkhill.services.auth.AuthState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import java.io.File

/**
 * The tools on every screen: what this build talks to, what the current
 * screen received, clearing cached data, and signing out.
 */
object AppTools {
    fun all(
        environment: AppEnvironment,
        tracker: CurrentScreenTracker,
        auth: AuthService,
        cacheDirectory: File,
        scope: CoroutineScope,
    ): List<DevTool> = listOf(
        DevTool(id = "app.build", title = "Build") {
            ToolValueRow("Environment", environment.name)
            ToolValueRow("Backend", environment.backend?.url ?: "No network", Modifier.testTag("devTools.build.backend"))
        },
        DevTool(id = "app.screen", title = "Screen") {
            val current = tracker.current
            ToolValueRow(
                "Current screen",
                current?.key ?: "None",
                Modifier.testTag("devTools.currentScreen").clickable { showPage("Current screen") { CurrentScreenPage(tracker) } },
            )
        },
        DevTool(id = "app.data", title = "Data") {
            ClearCachedDataRow(cacheDirectory)
        },
        DevTool(id = "app.session", title = "Session") {
            val user = (auth.state.collectAsState().value as? AuthState.SignedIn)?.user
            if (user != null) {
                Row(Modifier.fillMaxWidth().padding(vertical = 12.dp)) {
                    Text("Signed in as", color = ParkHill.colors.ink, modifier = Modifier.weight(1f))
                    Text(user.email ?: user.id, color = ParkHill.colors.inkMuted, modifier = Modifier.testTag("devTools.session.user"))
                }
                ToolActionRow("Sign out", Modifier.testTag("devTools.signOut"), destructive = true) {
                    closeMenu()
                    scope.launch { auth.signOut() }
                }
            } else {
                Text("Not signed in", color = ParkHill.colors.inkMuted, modifier = Modifier.padding(vertical = 12.dp))
            }
        },
    )

    @OptIn(ExperimentalSerializationApi::class)
    private val printer = Json { prettyPrint = true; prettyPrintIndent = "  " }

    /** Screen data as indented JSON with sorted keys, for reading and copying. */
    fun formattedJSON(value: JsonElement): String = printer.encodeToString(JsonElement.serializer(), sorted(value))

    private fun sorted(value: JsonElement): JsonElement = when (value) {
        is JsonObject -> JsonObject(value.entries.sortedBy { it.key }.associate { it.key to sorted(it.value) })
        is JsonArray -> JsonArray(value.map(::sorted))
        else -> value
    }
}

/** A label and its value on one row. */
@Composable
fun ToolValueRow(label: String, value: String, modifier: Modifier = Modifier) {
    Row(modifier.fillMaxWidth().padding(vertical = 12.dp)) {
        Text(label, color = ParkHill.colors.ink, modifier = Modifier.weight(1f))
        Text(value, color = ParkHill.colors.inkMuted)
    }
}

/** A row that selects on tap, with a checkmark when selected. */
@Composable
fun ToolCheckRow(isSelected: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit, label: @Composable () -> Unit) {
    Row(
        modifier.fillMaxWidth().selectable(selected = isSelected, onClick = onClick).padding(vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.weight(1f)) { label() }
        if (isSelected) Icon(Icons.Filled.Check, contentDescription = null, tint = ParkHill.colors.ink)
    }
}

/** A tappable row that acts. */
@Composable
fun ToolActionRow(title: String, modifier: Modifier = Modifier, destructive: Boolean = false, enabled: Boolean = true, onClick: () -> Unit) {
    val color = when {
        !enabled -> ParkHill.colors.inkMuted
        destructive -> ParkHill.colors.danger
        else -> ParkHill.colors.ink
    }
    Text(title, color = color, modifier = modifier.fillMaxWidth().clickable(enabled = enabled, onClick = onClick).padding(vertical = 12.dp))
}

/** The current screen's key and data, copyable. */
@Composable
private fun CurrentScreenPage(tracker: CurrentScreenTracker) {
    val envelope = tracker.current
    val context = LocalContext.current
    var copied by remember { mutableStateOf(false) }
    Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState())) {
        if (envelope == null) {
            Text("No backend-driven screen is showing.", color = ParkHill.colors.inkMuted)
            return@Column
        }
        val json = remember(envelope) { AppTools.formattedJSON(envelope.data) }
        Text("Key", style = ParkHill.label, color = ParkHill.colors.inkMuted)
        SelectionContainer {
            Text(envelope.key, fontFamily = FontFamily.Monospace, color = ParkHill.colors.ink, modifier = Modifier.padding(vertical = 8.dp).testTag("devTools.currentScreen.key"))
        }
        Text("Data", style = ParkHill.label, color = ParkHill.colors.inkMuted, modifier = Modifier.padding(top = 12.dp))
        SelectionContainer {
            Text(json, fontFamily = FontFamily.Monospace, fontSize = 12.sp, color = ParkHill.colors.ink, modifier = Modifier.padding(vertical = 8.dp).testTag("devTools.currentScreen.data"))
        }
        ToolActionRow(if (copied) "Copied" else "Copy data", Modifier.testTag("devTools.currentScreen.copy")) {
            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            clipboard.setPrimaryClip(ClipData.newPlainText("Screen data", json))
            copied = true
        }
    }
}

/** Deletes everything the app caches, after a confirmation. The session and the screen showing are untouched. */
@Composable
private fun ClearCachedDataRow(directory: File) {
    var isConfirming by remember { mutableStateOf(false) }
    var cleared by remember { mutableStateOf(false) }
    ToolActionRow(if (cleared) "Cached data cleared" else "Clear cached data", Modifier.testTag("devTools.clearCache"), enabled = !cleared) {
        isConfirming = true
    }
    if (isConfirming) {
        AlertDialog(
            onDismissRequest = { isConfirming = false },
            title = { Text("Clear cached data?") },
            text = { Text("Cached screens are deleted. The next launch fetches everything again.") },
            confirmButton = {
                TextButton(onClick = {
                    directory.deleteRecursively()
                    cleared = true
                    isConfirming = false
                }, modifier = Modifier.testTag("devTools.clearCache.confirm")) { Text("Clear cached data", color = ParkHill.colors.danger) }
            },
            dismissButton = { TextButton(onClick = { isConfirming = false }) { Text("Cancel", color = ParkHill.colors.ink) } },
        )
    }
}
