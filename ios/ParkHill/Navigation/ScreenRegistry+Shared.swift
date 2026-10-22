extension ScreenRegistry {
    /// Screens every configuration can show.
    mutating func registerSharedScreens(auth: any AuthService) {
        register("auth.sign_in", data: SignInScreenData.self) { data in
            SignInScreen(data: data, auth: auth)
        }
        register("home.root", data: HomeRootData.self) { data in
            HomeRootScreen(data: data)
        }
        register("community.home", data: CommunityHomeData.self) { data in
            CommunityHomeScreen(data: data)
        }
    }
}
