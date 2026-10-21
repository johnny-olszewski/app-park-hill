package app.parkhill.navigation

import app.parkhill.screens.community.CommunityHomeData
import app.parkhill.screens.community.CommunityHomeScreen
import app.parkhill.screens.home.HomeRootData
import app.parkhill.screens.home.HomeRootScreen
import app.parkhill.screens.auth.SignInScreen
import app.parkhill.screens.auth.SignInScreenData
import app.parkhill.services.auth.AuthService

/** Screens every flavor can show. */
fun ScreenRegistry.registerSharedScreens(auth: AuthService) {
    register("auth.sign_in", SignInScreenData.serializer()) { data -> SignInScreen(data, auth) }
    register("home.root", HomeRootData.serializer()) { data -> HomeRootScreen(data) }
    register("community.home", CommunityHomeData.serializer()) { data -> CommunityHomeScreen(data) }
}
