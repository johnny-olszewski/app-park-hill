package app.parkhill.services.backend

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** The signed-in app's tabs (`get_tabs`, contract/README.md): in backend order, each with its root screen embedded. */
@Serializable
data class TabsResponse(val tabs: List<TabItem>)

/** One tab: its title for the locale, a bundled icon key and its root screen. */
@Serializable
data class TabItem(
    val id: String,
    val title: String,
    @SerialName("icon_key") val iconKey: String,
    val screen: ScreenEnvelope,
)
