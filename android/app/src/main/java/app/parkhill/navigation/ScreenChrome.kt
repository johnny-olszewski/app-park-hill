package app.parkhill.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.staticCompositionLocalOf

/**
 * What a screen asks of the top app bar that shows it, the way SwiftUI
 * screens declare toolbar items: `actions` after its backend toolbar, or in
 * its place when `replacesToolbar`; `navigationIcon` in place of the back or
 * close button; and whether pull to refresh is on. Edit mode's Edit, Done
 * and Cancel are the first use. A screen sets it with [ScreenChromeEffect].
 */
class ScreenChrome(
    val actions: @Composable () -> Unit = {},
    val replacesToolbar: Boolean = false,
    val navigationIcon: (@Composable () -> Unit)? = null,
    val refreshable: Boolean = true,
)

/** The screen being shown, for [ScreenChromeEffect]; provided by [ScreenHost]. */
internal val LocalShownScreen = staticCompositionLocalOf<ScreenModel?> { null }

/** Shows `chrome` in the bar of the screen this is composed in, for as long as it is composed. */
@Composable
fun ScreenChromeEffect(chrome: ScreenChrome) {
    val screen = LocalShownScreen.current ?: return
    DisposableEffect(screen) {
        onDispose { screen.chrome = null }
    }
    SideEffect { screen.chrome = chrome }
}

/** A screen's top app bar actions: its backend toolbar, unless the screen replaces it, then what the screen adds. */
@Composable
internal fun ScreenBarActions(screen: ScreenModel) {
    val chrome = screen.chrome
    if (chrome?.replacesToolbar != true) ToolbarActions(screen)
    chrome?.actions?.invoke()
}
