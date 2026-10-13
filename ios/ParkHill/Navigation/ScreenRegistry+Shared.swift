extension ScreenRegistry {
    /// Screens every configuration can show.
    mutating func registerSharedScreens(auth: any AuthService) {
        register("auth.sign_in", data: SignInScreenData.self) { data in
            SignInScreen(data: data, auth: auth)
        }
    }
}
