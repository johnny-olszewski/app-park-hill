extension ScreenRegistry {
    /// Mock-only screens (keys ending in `.mock`). This file exists only in
    /// mock sources, so these screens never compile into other configurations.
    /// The persona picker, `auth.sign_in.mock`, arrives in IOS-006.
    mutating func registerMockScreens() {}
}
