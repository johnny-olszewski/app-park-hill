import Foundation
import Testing
@testable import ParkHill

struct AppEnvironmentTests {
    @Test func bindingDeclaresANamedEnvironment() {
        #expect(!ServiceBinding.environment.name.isEmpty)
    }

    @Test func backendLabelIsTheURLOrNone() {
        let target = BackendTarget(url: URL(string: "http://127.0.0.1:54321")!, anonKey: "key")
        #expect(AppEnvironment(name: "A", backend: target).backendLabel == "http://127.0.0.1:54321")
        #expect(AppEnvironment(name: "B", backend: nil).backendLabel == "none")
    }
}
