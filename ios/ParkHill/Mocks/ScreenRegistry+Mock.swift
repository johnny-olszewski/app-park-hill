extension ScreenRegistry {
    /// Mock-only screens (keys ending in `.mock`). This file exists only in
    /// mock sources, so these screens never compile into other configurations.
    mutating func registerMockScreens(auth: MockAuthService) {
        register(PersonaPickerData.screenKey, data: PersonaPickerData.self) { data in
            PersonaPickerScreen(data: data, auth: auth)
        }
    }
}
