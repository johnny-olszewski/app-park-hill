import Foundation
import Testing
@testable import ParkHill

struct MockBackendServiceTests {
    private func expected(_ path: String) throws -> ScreenEnvelope {
        try JSONDecoder().decode(ScreenEnvelope.self, from: TestMockResponses.data(path))
    }

    @Test func theEntryIsTheRecordedProductionSignIn() async throws {
        let entry = try await MockBackendService(environment: .mock).getEntry(locale: "en")
        #expect(entry == (try expected("get_entry.json")))
        #expect(entry.key == "auth.sign_in")
    }

    @Test func whoamiReturnsTheSignedInPersonasProfile() async throws {
        let personaState = MockPersonaState()
        let service = MockBackendService(responses: .bundled, personaState: personaState)
        await #expect(throws: BackendError.unauthorized) { _ = try await service.whoami() }
        personaState.current = "attendee"
        #expect(try await service.whoami().displayName == "Attendee")
    }

    @Test func getTabsReturnsTheSignedInPersonasTabs() async throws {
        let personaState = MockPersonaState()
        let service = MockBackendService(responses: .bundled, personaState: personaState)
        await #expect(throws: BackendError.unauthorized) { _ = try await service.getTabs(locale: "en") }
        personaState.current = "attendee"
        let expected = try JSONDecoder().decode(TabsResponse.self, from: TestMockResponses.data("attendee/get_tabs.json"))
        #expect(try await service.getTabs(locale: "en") == expected)
    }

    @Test func getScreenReadsTheScreenMockResponse() async throws {
        let service = MockBackendService(environment: .mock)
        #expect(try await service.getScreen(key: "auth.sign_in", locale: "en") == expected("get_screen.auth.sign_in.json"))
    }

    @Test func getScreenWithParamsReadsTheMockResponseForThoseParams() async throws {
        let personaState = MockPersonaState()
        personaState.current = "member_two"
        let service = MockBackendService(responses: .bundled, personaState: personaState)
        let groupID = "d44d5b87-37ce-5db5-9e33-43f477b42f1e"
        let screen = try await service.getScreen(key: "community.group", locale: "en", params: ["group_id": .string(groupID)])
        #expect(screen == (try expected("member_two/get_screen.community.group@group_id=\(groupID).json")))
    }

    @Test func getScreenWithParamsFallsBackToTheScreenAlone() async throws {
        let service = MockBackendService(environment: .mock)
        let screen = try await service.getScreen(key: "auth.sign_in", locale: "en", params: ["unused": .string("x")])
        #expect(screen == (try expected("get_screen.auth.sign_in.json")))
    }

    @Test func mockResponseNamesSortParamsByName() {
        #expect(MockResponseStore.name("get_screen.a", params: [:]) == "get_screen.a")
        #expect(MockResponseStore.name("get_screen.a", params: ["z": .number(2), "b": .string("x")]) == "get_screen.a@b=x&z=2")
        #expect(MockResponseStore.name("get_screen.a", params: ["b": .bool(true)]) == "get_screen.a")
    }

    @Test func unknownScreenKeyThrowsUnknownScreen() async {
        let service = MockBackendService(environment: .mock)
        await #expect(throws: BackendError.unknownScreen) {
            _ = try await service.getScreen(key: "does.not_exist", locale: "en")
        }
    }

    @Test func personaMockResponseWinsOverTheSharedOne() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root.appending(path: "admin"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data(#"{"key":"shared","data":{}}"#.utf8).write(to: root.appending(path: "get_entry.json"))
        try Data(#"{"key":"admin","data":{}}"#.utf8).write(to: root.appending(path: "admin/get_entry.json"))

        let personaState = MockPersonaState()
        let service = MockBackendService(responses: MockResponseStore(root: root), personaState: personaState)

        #expect(try await service.getEntry(locale: "en").key == "shared")
        personaState.current = "admin"
        #expect(try await service.getEntry(locale: "en").key == "admin")
        personaState.current = "attendee"
        #expect(try await service.getEntry(locale: "en").key == "shared")
    }

    @Test func aCallSucceedsForASignedInPersona() async throws {
        let personaState = MockPersonaState()
        let service = MockBackendService(responses: .bundled, personaState: personaState)
        await #expect(throws: BackendError.unauthorized) {
            try await service.call(function: "leave_group", params: [:], locale: "en")
        }
        personaState.current = "member_one"
        #expect(try await service.call(function: "leave_group", params: ["p_group_id": .string("g")], locale: "en") == .object([:]))
    }

    @Test func aCallWithARecordedOkResultReturnsIt() async throws {
        let personaState = MockPersonaState()
        personaState.current = "leader"
        let service = MockBackendService(responses: .bundled, personaState: personaState)
        let expected = try JSONDecoder().decode(JSONValue.self, from: TestMockResponses.data("save_group_changes.ok.json"))
        #expect(try await service.call(function: "save_group_changes", params: [:], locale: "en") == expected)
    }

    @Test func malformedMockResponseThrowsDecoding() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data(#"{"nope":true}"#.utf8).write(to: root.appending(path: "get_entry.json"))

        let service = MockBackendService(responses: MockResponseStore(root: root), personaState: MockPersonaState())
        await #expect(throws: BackendError.decoding) {
            _ = try await service.getEntry(locale: "en")
        }
    }
}
