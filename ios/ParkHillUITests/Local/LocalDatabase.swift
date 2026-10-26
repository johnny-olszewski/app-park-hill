import Foundation
import XCTest

/// Changes group rows in local Supabase for a Local UI test, through its REST
/// API with local Supabase's service-role key, and puts them back when the
/// test ends. The key is the same demo key on every machine, like the
/// committed anon key (guide 5.2 rule 4), and lives only in test sources.
@MainActor
final class LocalDatabase {
    private static let url = URL(string: "http://127.0.0.1:54321/rest/v1")!
    private static let serviceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

    private var snapshots: [(group: String, details: [String: Any], members: [[String: Any]], leaders: [[String: Any]])] = []

    /// The id of the group named `name`.
    func groupID(named name: String) async throws -> String {
        let rows = try await request("GET", "groups?select=id&name=eq.\(Self.encode(name))")
        return try XCTUnwrap(rows.first?["id"] as? String, "group \(name)")
    }

    /// The id of the person shown as `displayName`.
    func userID(named displayName: String) async throws -> String {
        let rows = try await request("GET", "profiles?select=id&display_name=eq.\(Self.encode(displayName))")
        return try XCTUnwrap(rows.first?["id"] as? String, "person \(displayName)")
    }

    /// Remembers `group`'s details, members and leaders, so `restore()` puts
    /// them back whatever the test or the app changes.
    func keep(_ group: String) async throws {
        let details = try await request("GET", "groups?select=name,description,meeting_day,meeting_time,location&id=eq.\(group)")
        snapshots.append((
            group,
            try XCTUnwrap(details.first),
            try await request("GET", "group_members?select=*&group_id=eq.\(group)"),
            try await request("GET", "group_leaders?select=*&group_id=eq.\(group)")
        ))
    }

    /// Whether `user` is a member of `group`.
    func isMember(_ user: String, of group: String) async throws -> Bool {
        !(try await request("GET", "group_members?select=user_id&group_id=eq.\(group)&user_id=eq.\(user)")).isEmpty
    }

    /// Ends `user`'s membership of `group`, and their leadership with it.
    func removeMember(_ user: String, from group: String) async throws {
        try await request("DELETE", "group_members?group_id=eq.\(group)&user_id=eq.\(user)")
    }

    /// Makes `user`, already a member, a leader of `group`.
    func makeLeader(_ user: String, of group: String) async throws {
        try await request("POST", "group_leaders", body: [["group_id": group, "user_id": user]])
    }

    /// Puts every kept group's details, members and leaders back as they were.
    func restore() async throws {
        for snapshot in snapshots.reversed() {
            try await request("PATCH", "groups?id=eq.\(snapshot.group)", body: snapshot.details)
            try await request("DELETE", "group_members?group_id=eq.\(snapshot.group)")
            if !snapshot.members.isEmpty { try await request("POST", "group_members", body: snapshot.members) }
            if !snapshot.leaders.isEmpty { try await request("POST", "group_leaders", body: snapshot.leaders) }
        }
        snapshots = []
    }

    @discardableResult
    private func request(_ method: String, _ path: String, body: Any? = nil) async throws -> [[String: Any]] {
        var request = URLRequest(url: URL(string: "\(Self.url.absoluteString)/\(path)")!)
        request.httpMethod = method
        request.setValue(Self.serviceKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Self.serviceKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        XCTAssertTrue((200..<300).contains(status), "\(method) \(path): HTTP \(status) \(String(decoding: data, as: UTF8.self))")
        return (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
    }

    private static func encode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? value
    }
}
