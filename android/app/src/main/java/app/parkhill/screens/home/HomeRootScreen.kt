package app.parkhill.screens.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import app.parkhill.contract.HomeRootData
import app.parkhill.design.ParkHill

/** The Home tab's root screen. Empty for now (EP-02). */
@Composable
fun HomeRootScreen(@Suppress("UNUSED_PARAMETER") data: HomeRootData) {
    Box(Modifier.fillMaxSize().background(ParkHill.colors.surface))
}
