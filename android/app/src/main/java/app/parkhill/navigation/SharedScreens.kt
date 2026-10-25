package app.parkhill.navigation

import app.parkhill.contract.CommunityGroupData
import app.parkhill.contract.CommunityHomeData
import app.parkhill.contract.HomeRootData
import app.parkhill.contract.ScreenKey
import app.parkhill.contract.SignInScreenData
import app.parkhill.screens.auth.SignInScreen
import app.parkhill.screens.community.CommunityGroupScreen
import app.parkhill.screens.community.CommunityHomeScreen
import app.parkhill.screens.home.HomeRootScreen
import app.parkhill.services.auth.AuthService

/** Screens every flavor can show. */
fun ScreenRegistry.registerSharedScreens(auth: AuthService) {
    register(ScreenKey.authSignIn, SignInScreenData.serializer()) { data -> SignInScreen(data, auth) }
    register(ScreenKey.homeRoot, HomeRootData.serializer()) { data -> HomeRootScreen(data) }
    register(ScreenKey.communityHome, CommunityHomeData.serializer()) { data -> CommunityHomeScreen(data) }
    register(ScreenKey.communityGroup, CommunityGroupData.serializer(), title = { it.title }) { data -> CommunityGroupScreen(data) }
}
