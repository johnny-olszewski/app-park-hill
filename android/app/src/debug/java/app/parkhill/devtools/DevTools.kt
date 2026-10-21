// Compiled only in debug builds (src/debug).
package app.parkhill.devtools

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.view.ViewGroup
import androidx.activity.ComponentActivity
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import app.parkhill.app.AppServices
import app.parkhill.cache.EntryCache
import kotlinx.coroutines.MainScope
import app.parkhill.design.ParkHillTheme
import app.parkhill.environment.AppEnvironment
import app.parkhill.navigation.ScreenTracker

typealias AppDevTools = DevTools

/**
 * Debug builds' dev tools (EP-06): the pill and menu over every activity, the
 * current screen for the menu, and the tools it offers. Release builds compile
 * `NoDevTools` instead, so nothing here ships.
 */
class DevTools(private val application: Application, services: AppServices) {
    val environment: AppEnvironment = services.environment
    val tracker = CurrentScreenTracker()
    val registry = DevToolRegistry()

    /** Whether the menu is showing. Snapshot state, read by the overlay. */
    var isMenuOpen by mutableStateOf(false)

    /** Outlives the menu, so an action it starts (such as signing out) finishes after it closes. */
    val scope = MainScope()

    init {
        AppTools.all(environment, tracker, services.auth, EntryCache.cacheDirectory(application.filesDir), scope)
            .forEach(registry::registerAppTool)
        registerEnvironmentTools(services)
    }

    val screenTracker: ScreenTracker get() = tracker

    /**
     * Adds the overlay over each activity's content once it is set. Dialogs
     * and bottom sheets are separate windows and cover it while open
     * (decision log, 2026-10-20).
     */
    fun install() {
        application.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
            override fun onActivityStarted(activity: Activity) = attach(activity)
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) = Unit
            override fun onActivityResumed(activity: Activity) = Unit
            override fun onActivityPaused(activity: Activity) = Unit
            override fun onActivityStopped(activity: Activity) = Unit
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) = Unit
            override fun onActivityDestroyed(activity: Activity) = Unit
        })
    }

    private fun attach(activity: Activity) {
        // Compose needs the activity's lifecycle and saved state; only ComponentActivity has them.
        if (activity !is ComponentActivity) return
        // On the decor view, above the content, so the activity's own content stays only its own.
        val decor = activity.window.decorView as? ViewGroup ?: return
        if (decor.findViewWithTag<ComposeView>(OVERLAY_TAG) != null) return
        val overlay = ComposeView(activity).apply {
            tag = OVERLAY_TAG
            // Set here because the activity may not have set its own content yet.
            setViewTreeLifecycleOwner(activity)
            setViewTreeSavedStateRegistryOwner(activity)
            setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed)
            setContent { ParkHillTheme { DevToolsOverlay(this@DevTools) } }
        }
        decor.addView(overlay, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
    }

    private companion object {
        const val OVERLAY_TAG = "devTools.overlay"
    }
}
