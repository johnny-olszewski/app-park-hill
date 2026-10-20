package app.parkhill.devtools

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.isSystemInDarkTheme
import app.parkhill.design.ParkHill

/** The overlay's content: the pill, centered just below the status bar, and the menu it opens on a long press. */
@Composable
fun DevToolsOverlay(devTools: DevTools) {
    // Only the pill takes touches; everywhere else they fall through to the app.
    Box(Modifier.fillMaxWidth().windowInsetsPadding(WindowInsets.statusBars), contentAlignment = Alignment.TopCenter) {
        DevToolsPill(
            name = devTools.environment.name,
            isArmed = devTools.registry.warnings.isNotEmpty(),
            modifier = Modifier.pointerInput(Unit) { detectTapGestures(onLongPress = { devTools.isMenuOpen = true }) },
        )
    }
    if (devTools.isMenuOpen) {
        DevToolsMenu(devTools, onClose = { devTools.isMenuOpen = false })
    }
}

/** The environment name, with an alert icon while a tool has armed a failure. */
@Composable
fun DevToolsPill(name: String, isArmed: Boolean, modifier: Modifier = Modifier) {
    // Stays small at the largest font scales, so it never grows over the app's controls.
    val density = LocalDensity.current
    CompositionLocalProvider(LocalDensity provides Density(density.density, density.fontScale.coerceAtMost(1.3f))) {
        Row(
            modifier
                .padding(top = 2.dp)
                .semantics { stateDescription = if (isArmed) "Failure armed" else "" }
                .testTag("devTools.pill")
                .background(ParkHill.colors.surfaceRaised, CircleShape)
                .border(1.5.dp, ParkHill.colors.sky, CircleShape)
                .padding(horizontal = 10.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(name.uppercase(), color = ParkHill.colors.ink, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 0.7.sp)
            if (isArmed) {
                Icon(Icons.Filled.Warning, contentDescription = null, tint = devToolsWarning(), modifier = Modifier.size(12.dp).testTag("devTools.pill.armed"))
            }
        }
    }
}

/** The menu: armed warnings first, then the current screen's tools, then the app tools. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DevToolsMenu(devTools: DevTools, onClose: () -> Unit) {
    var shownPage by remember { mutableStateOf<Pair<String, @Composable () -> Unit>?>(null) }
    val scope = remember {
        object : DevToolScope {
            override fun showPage(title: String, page: @Composable () -> Unit) {
                shownPage = title to page
            }

            override fun closeMenu() = onClose()
        }
    }
    ModalBottomSheet(
        onDismissRequest = onClose,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = ParkHill.colors.surface,
    ) {
        val shown = shownPage
        Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            if (shown != null) {
                BackHandler { shownPage = null }
                TextButton(onClick = { shownPage = null }, modifier = Modifier.testTag("devTools.back")) { Text("Back", color = ParkHill.colors.ink) }
            }
            Text(
                shown?.first ?: "${devTools.environment.name} menu",
                color = ParkHill.colors.ink,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.weight(1f).padding(horizontal = 12.dp),
            )
            TextButton(onClick = onClose, modifier = Modifier.testTag("devTools.done")) { Text("Done", color = ParkHill.colors.ink) }
        }
        if (shown != null) {
            Box(Modifier.padding(horizontal = 20.dp).navigationBarsPadding()) { shown.second() }
            return@ModalBottomSheet
        }
        val registry = devTools.registry
        val warnings = registry.warnings
        val tools = registry.tools(devTools.tracker.current?.key) + registry.appTools
        LazyColumn(Modifier.fillMaxWidth().padding(horizontal = 20.dp).testTag("devTools.menu")) {
            items(warnings) { warning ->
                Row(Modifier.padding(vertical = 8.dp).testTag("devTools.warning"), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Warning, contentDescription = null, tint = devToolsWarning(), modifier = Modifier.size(16.dp))
                    Text(warning, color = devToolsWarning(), modifier = Modifier.padding(start = 8.dp))
                }
            }
            items(tools, key = { it.id }) { tool ->
                Text(tool.title.uppercase(), style = ParkHill.label, color = ParkHill.colors.inkMuted, modifier = Modifier.padding(top = 16.dp))
                tool.content(scope)
            }
            item { Box(Modifier.navigationBarsPadding().padding(bottom = 16.dp)) }
        }
    }
}

/** Armed failures in the pill and menu. Dev tools only, so not a brand token. */
@Composable
private fun devToolsWarning(): Color = if (isSystemInDarkTheme()) Color(0xFFF2C46B) else Color(0xFF8A5A00)
