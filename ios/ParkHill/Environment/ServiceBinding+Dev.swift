// Compiled only in Dev configurations (Config/App.xcconfig).

enum ServiceBinding {
    static let environment = AppEnvironment(
        name: "Dev",
        backend: .fromInfoPlist()
    )
}
