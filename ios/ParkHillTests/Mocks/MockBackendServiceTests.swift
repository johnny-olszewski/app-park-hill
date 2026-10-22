import Foundation
import Testing
@testable import ParkHill

struct MockBackendServiceTests {
    private func expected(_ path: String) throws -> ScreenEnvelope {
        try JSONDecoder().decode(ScreenEnvelope.self, from: TestFixtures.data(path))
    }

    @Test func theEntryIsTheRecordedProductionSignIn() async throws {
        let entry = try await MockBackendService(environment: .mock).getEntry(locale: "en")
        #expect(entry == (try expected("get_entry.json")))
        #expect(entry.key == "auth.sign_in")
    }

    @Test func whoamiReturnsTheSignedInPersonasProfile() async throws {
        let personaState = MockPersonaState()
        let service = MockBackendService(fixtures: .bundled, personaState: personaState)
        await #expect(throws: BackendError.unauthorized) { _ = try await service.whoami() }
        personaState.current = "attendee"
        #expect(try await service.whoami().displayName == "Attendee")
    }

    @Test func getTabsReturnsTheSignedInPersonasTabs() async throws {
        let personaState = MockPersonaState()
        let service = MockBackendService(fixtures: .bundled, personaState: personaState)
        await #expect(throws: BackendError.unauthorized) { _ = try await service.getTabs(locale: "en") }
        personaState.current = "attendee"
        let expected = try JSONDecoder().decode(TabsResponse.self, from: TestFixtures.data("attendee/get_tabs.json"))
        #expect(try await service.getTabs(locale: "en") == expected)
    }

    @Test func getScreenReadsTheScreenFixture() async throws {
        let service = MockBackendService(environment: .mock)
        #expect(try await service.getScreen(key: "auth.sign_in", locale: "en") == expected("get_screen.auth.sign_in.json"))
    }

    @Test func unknownScreenKeyThrowsUnknownScreen() async {
        let service = MockBackendService(environment: .mock)
        await #expect(throws: BackendError.unknownScreen) {
            _ = try await service.getScreen(key: "does.not_exist", locale: "en")
        }
    }

    @Test func personaFixtureWinsOverTheSharedOne() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root.appending(path: "admin"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data(#"{"key":"shared","data":{}}"#.utf8).write(to: root.appending(path: "get_entry.json"))
        try Data(#"{"key":"admin","data":{}}"#.utf8).write(to: root.appending(path: "admin/get_entry.json"))

        let personaState = MockPersonaState()
        let service = MockBackendService(fixtures: FixtureStore(root: root), personaState: personaState)

        #expect(try await service.getEntry(locale: "en").key == "shared")
        personaState.current = "admin"
        #expect(try await service.getEntry(locale: "en").key == "admin")
        personaState.current = "attendee"
        #expect(try await service.getEntry(locale: "en").key == "shared")
    }

    @Test func malformedFixtureThrowsDecoding() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data(#"{"nope":true}"#.utf8).write(to: root.appending(path: "get_entry.json"))

        let service = MockBackendService(fixtures: FixtureStore(root: root), personaState: MockPersonaState())
        await #expect(throws: BackendError.decoding) {
            _ = try await service.getEntry(locale: "en")
        }
    }
}
