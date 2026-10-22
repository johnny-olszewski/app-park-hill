package app.parkhill.navigation

import app.parkhill.contract.ScreenKey
import app.parkhill.screens.community.CommunityHomeData
import app.parkhill.screens.community.CommunityHomeScreen
import app.parkhill.screens.home.HomeRootData
import app.parkhill.screens.home.HomeRootScreen
import app.parkhill.screens.auth.SignInScreen
import app.parkhill.screens.auth.SignInScreenData
import app.parkhill.services.auth.AuthService

/** Screens every flavor can show. */
fun ScreenRegistry.registerSharedScreens(auth: AuthService) {
    register(ScreenKey.authSignIn, SignInScreenData.serializer()) { data -> SignInScreen(data, auth) }
    register(ScreenKey.homeRoot, HomeRootData.serializer()) { data -> HomeRootScreen(data) }
    register(ScreenKey.communityHome, CommunityHomeData.serializer()) { data -> CommunityHomeScreen(data) }
}
