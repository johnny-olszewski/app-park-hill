import Foundation

/// Everything about the user stored on the device outside the session, which
/// the auth service deletes on every sign-out (specs/AUTH.md 4.4).
struct LocalUserData: Sendable {
    let directories: [URL]

    static var standard: LocalUserData {
        LocalUserData(directories: [CacheDirectory.url, UserFilesDirectory.url])
    }

    func wipe() {
        for directory in directories {
            try? FileManager.default.removeItem(at: directory)
        }
    }
}

/// Root for files the app keeps for the signed-in user. Sign-out deletes it.
enum UserFilesDirectory {
    static var url: URL {
        URL.applicationSupportDirectory.appending(path: "UserFiles", directoryHint: .isDirectory)
    }
}
