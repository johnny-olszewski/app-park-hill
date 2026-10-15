import Foundation
import Testing
@testable import ParkHill

@MainActor
struct AppToolsTests {
    @Test func formatsScreenDataAsSortedIndentedJSON() {
        let json = AppTools.formattedJSON(.object(["title": .string("Sign in"), "actions": .array([])]))
        #expect(json == """
        {
          "actions" : [

          ],
          "title" : "Sign in"
        }
        """)
    }

    @Test func keepsSlashesReadable() {
        #expect(AppTools.formattedJSON(.string("http://127.0.0.1")) == #""http://127.0.0.1""#)
    }

    @Test func offersBuildScreenDataAndSessionTools() {
        let tools = AppTools.all(
            environment: AppEnvironment(name: "Test", backend: nil),
            tracker: CurrentScreenTracker(),
            session: SessionTracker(auth: StubAuthService()),
            auth: StubAuthService()
        )
        #expect(tools.map(\.id) == ["app.build", "app.screen", "app.data", "app.session"])
        #expect(tools.allSatisfy { $0.warning == nil })
    }

    @Test func followsTheSignedInState() async throws {
        let auth = StubAuthService()
        let session = SessionTracker(auth: auth)
        #expect(!session.isSignedIn)
        auth.send(.signedIn(AuthUser(id: "u", email: "a@b.c")))
        for _ in 0..<100 where !session.isSignedIn {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(session.isSignedIn)
    }
}
