extension ScreenRegistry {
    /// Screens every configuration can show.
    mutating func registerSharedScreens(auth: any AuthService) {
        register(ScreenKey.authSignIn, data: SignInScreenData.self) { data in
            SignInScreen(data: data, auth: auth)
        }
        register(ScreenKey.homeRoot, data: HomeRootData.self) { data in
            HomeRootScreen(data: data)
        }
        register(ScreenKey.communityHome, data: CommunityHomeData.self) { data in
            CommunityHomeScreen(data: data)
        }
    }
}
