package app.parkhill.navigation

import app.parkhill.screens.auth.SignInScreen
import app.parkhill.screens.auth.SignInScreenData
import app.parkhill.services.auth.AuthService

/** Screens every flavor can show. */
fun ScreenRegistry.registerSharedScreens(auth: AuthService) {
    register("auth.sign_in", SignInScreenData.serializer()) { data -> SignInScreen(data, auth) }
}
