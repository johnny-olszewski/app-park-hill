// Compiled only in the Mock configuration (Config/Mock.xcconfig).

typealias AppBackendService = MockBackendService

enum ServiceBinding {
    static let environment = AppEnvironment.mock
}
