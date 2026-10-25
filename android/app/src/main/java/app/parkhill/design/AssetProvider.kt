package app.parkhill.design

import androidx.annotation.DrawableRes
import app.parkhill.R

/**
 * Resolves the backend's image keys to bundled assets (guide decision log:
 * bundled first, remote later behind this type). Placeholder Material icons
 * until design delivers artwork under the same keys.
 */
object AssetProvider {
    private val tabIcons = mapOf(
        "tab.home" to R.drawable.ic_tab_home,
        "tab.community" to R.drawable.ic_tab_community,
    )

    /** The icon for a tab's `icon_key`; an unknown key gets the fallback, so a new key can never break the tab bar. */
    @DrawableRes
    fun tabIcon(key: String): Int = tabIcons[key] ?: R.drawable.ic_tab_fallback

    /** Whether `key` has its own bundled icon rather than the fallback. */
    fun hasTabIcon(key: String): Boolean = key in tabIcons

    private val toolbarIcons = mapOf(
        "toolbar.browse" to R.drawable.ic_toolbar_browse,
    )

    /** The icon for a toolbar item's `icon_key`; an unknown key gets the fallback, so a new key can never break a bar. */
    @DrawableRes
    fun toolbarIcon(key: String): Int = toolbarIcons[key] ?: R.drawable.ic_toolbar_fallback

    /** Whether `key` has its own bundled toolbar icon rather than the fallback. */
    fun hasToolbarIcon(key: String): Boolean = key in toolbarIcons
}
