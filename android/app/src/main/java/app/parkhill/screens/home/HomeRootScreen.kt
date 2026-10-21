package app.parkhill.screens.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import app.parkhill.design.ParkHill
import kotlinx.serialization.Serializable

/** `home.root` data: empty until Home has content. */
@Serializable
class HomeRootData

/** The Home tab's root screen. Empty for now (EP-02). */
@Composable
fun HomeRootScreen(@Suppress("UNUSED_PARAMETER") data: HomeRootData) {
    Box(Modifier.fillMaxSize().background(ParkHill.colors.surface))
}
