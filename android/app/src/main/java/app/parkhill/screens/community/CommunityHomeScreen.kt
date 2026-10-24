package app.parkhill.screens.community

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import app.parkhill.contract.CommunityHomeData
import app.parkhill.design.ParkHill

/** The Community tab's root screen. Empty for now (EP-02). */
@Composable
fun CommunityHomeScreen(@Suppress("UNUSED_PARAMETER") data: CommunityHomeData) {
    Box(Modifier.fillMaxSize().background(ParkHill.colors.surface))
}
