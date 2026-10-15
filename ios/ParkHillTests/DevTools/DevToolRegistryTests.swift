import SwiftUI
import Testing
@testable import ParkHill

@MainActor
struct DevToolRegistryTests {
    private func tool(_ id: String, warning: String? = nil) -> DevTool {
        DevTool(id: id, title: id, warning: { warning }) { Text(id) }
    }

    @Test func aScreenToolAppearsOnlyForItsScreen() {
        var registry = DevToolRegistry()
        registry.register(tool("signIn"), forScreen: "auth.sign_in")
        #expect(registry.tools(forScreen: "auth.sign_in").map(\.id) == ["signIn"])
        #expect(registry.tools(forScreen: "community.home").isEmpty)
        #expect(registry.tools(forScreen: nil).isEmpty)
    }

    @Test func screenToolsKeepRegistrationOrder() {
        var registry = DevToolRegistry()
        registry.register(tool("first"), forScreen: "auth.sign_in")
        registry.register(tool("second"), forScreen: "auth.sign_in")
        #expect(registry.tools(forScreen: "auth.sign_in").map(\.id) == ["first", "second"])
    }

    @Test func appToolsAreSeparateFromScreenTools() {
        var registry = DevToolRegistry()
        registry.registerAppTool(tool("build"))
        #expect(registry.appTools.map(\.id) == ["build"])
        #expect(registry.tools(forScreen: "auth.sign_in").isEmpty)
    }

    @Test func noWarningsWhenNothingIsArmed() {
        var registry = DevToolRegistry()
        registry.register(tool("signIn"), forScreen: "auth.sign_in")
        registry.registerAppTool(tool("build"))
        #expect(registry.warnings.isEmpty)
    }

    @Test func warningsComeFromEveryScreenAndAppTool() {
        var registry = DevToolRegistry()
        registry.register(tool("signIn", warning: "Next sign-in will fail: Too many attempts"), forScreen: "auth.sign_in")
        registry.register(tool("other", warning: "Other armed"), forScreen: "community.home")
        registry.registerAppTool(tool("app", warning: "App armed"))
        #expect(registry.warnings == ["App armed", "Next sign-in will fail: Too many attempts", "Other armed"])
    }

    @Test func warningsFollowTheToolsState() {
        final class Armed { var text: String? }
        let armed = Armed()
        var registry = DevToolRegistry()
        registry.register(DevTool(id: "signIn", title: "Sign in", warning: { armed.text }) { EmptyView() }, forScreen: "auth.sign_in")
        #expect(registry.warnings.isEmpty)
        armed.text = "Armed"
        #expect(registry.warnings == ["Armed"])
    }
}
