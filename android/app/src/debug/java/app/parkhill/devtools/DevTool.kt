package app.parkhill.devtools

import androidx.compose.runtime.Composable

/**
 * One section of the dev tools menu: a title and its rows. A tool may report
 * a warning while it has armed something other than the normal result (for
 * example a sign-in that will fail); the pill and menu then show it.
 */
class DevTool(
    val id: String,
    val title: String,
    private val warningText: () -> String? = { null },
    val content: @Composable DevToolScope.() -> Unit,
) {
    /** Read while the menu or pill composes, so snapshot state the tool reads updates them. */
    val warning: String? get() = warningText()
}

/**
 * The tools the menu offers: each screen's own, by screen key, then the
 * app-wide ones. Adding a tool is registering one entry; screens never know.
 */
class DevToolRegistry {
    private val screenTools = mutableMapOf<String, MutableList<DevTool>>()
    private val _appTools = mutableListOf<DevTool>()
    val appTools: List<DevTool> get() = _appTools

    fun register(tool: DevTool, forScreen: String) {
        screenTools.getOrPut(forScreen) { mutableListOf() } += tool
    }

    fun registerAppTool(tool: DevTool) {
        _appTools += tool
    }

    /** The tools for the screen with `key`, in registration order. */
    fun tools(forScreen: String?): List<DevTool> = forScreen?.let { screenTools[it] }.orEmpty()

    /** Every armed warning, from any screen's tools or the app tools, so an armed failure is visible wherever the user is. */
    val warnings: List<String> get() = (screenTools.values.flatten() + _appTools).mapNotNull { it.warning }.sorted()
}

/** What a tool's rows can do to the menu around them. */
interface DevToolScope {
    /** Shows `page` in place of the menu, titled `title`, with a back button. */
    fun showPage(title: String, page: @Composable () -> Unit)

    /** Closes the menu, for example after an action that changes the screen. */
    fun closeMenu()
}
