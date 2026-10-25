extension ScreenRegistry {
    /// Screens every configuration can show.
    mutating func registerSharedScreens(auth: any AuthService) {
        register(ScreenKey.authSignIn, data: SignInScreenData.self) { data in
            SignInScreen(data: data, auth: auth)
        }
        register(ScreenKey.homeRoot, data: HomeRootData.self) { data in
            HomeRootScreen(data: data)
        }
        register(ScreenKey.communityHome, data: CommunityHomeData.self, isUsable: { CommunityHomeState($0) != nil }) { data in
            CommunityHomeScreen(data: data)
        }
        register(ScreenKey.communityGroup, data: CommunityGroupData.self) { data in
            CommunityGroupScreen(data: data)
        }
        register(ScreenKey.communityBrowse, data: CommunityBrowseData.self) { data in
            CommunityBrowseScreen(data: data)
        }
    }
}
