/// The one shape for any screen's content (contract/README.md). `data` stays
/// raw JSON here; the screen registry decodes it into the screen's own model.
struct ScreenEnvelope: Codable, Equatable, Sendable {
    let key: String
    let data: JSONValue
}
