/// The signed-in caller's profile (`whoami`, contract/README.md).
struct Profile: Decodable, Equatable, Sendable {
    let id: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}
