package app.parkhill.navigation

import app.parkhill.screens.auth.SignInScreen
import app.parkhill.screens.auth.SignInScreenData

/** Screens every flavor can show. */
fun ScreenRegistry.registerSharedScreens() {
    register("auth.sign_in", SignInScreenData.serializer()) { data -> SignInScreen(data) }
}
