import Foundation
import OSLog
import SwiftUI

/// Maps screen keys to screen factories (guide 5.1). The only way screens are
/// created: coordinators resolve envelopes here, views never build screens.
/// Each configuration's binding decides which screen sets are registered.
@MainActor
struct ScreenRegistry {
    private var factories: [String: (JSONValue) throws -> AnyView] = [:]
    private let tracker: (any ScreenTracker)?

    /// `tracker` is told when each resolved screen appears and disappears.
    init(tracker: (any ScreenTracker)? = nil) {
        self.tracker = tracker
    }

    /// Registers `key`. The screen's data is decoded into `Data` when an
    /// envelope with that key is resolved.
    mutating func register<Data: Decodable, Screen: View>(
        _ key: String,
        data: Data.Type,
        screen: @escaping (Data) -> Screen
    ) {
        precondition(factories[key] == nil, "Screen \(key) registered twice")
        factories[key] = { json in
            let decoded = try JSONDecoder().decode(Data.self, from: JSONEncoder().encode(json))
            return AnyView(screen(decoded))
        }
    }

    func isRegistered(_ key: String) -> Bool {
        factories[key] != nil
    }

    /// The screen for an envelope, or nil when its key is not registered or
    /// its data does not match the screen's model. Both are logged.
    func resolve(_ envelope: ScreenEnvelope) -> ResolvedScreen? {
        guard let factory = factories[envelope.key] else {
            Logger.navigation.error("Dropped unregistered screen key \(envelope.key, privacy: .public)")
            return nil
        }
        do {
            return ResolvedScreen(envelope: envelope, view: tracked(try factory(envelope.data), envelope: envelope))
        } catch {
            Logger.navigation.error("Dropped screen \(envelope.key, privacy: .public): data does not match its model")
            return nil
        }
    }

    private func tracked(_ view: AnyView, envelope: ScreenEnvelope) -> AnyView {
        guard let tracker else { return view }
        return AnyView(view.modifier(ScreenTracking(envelope: envelope, tracker: tracker)))
    }
}

/// A screen ready to show, with the envelope it was built from.
struct ResolvedScreen {
    let envelope: ScreenEnvelope
    let view: AnyView

    var key: String { envelope.key }
}

/// Reports one resolved screen's appearance to the tracker.
private struct ScreenTracking: ViewModifier {
    let envelope: ScreenEnvelope
    let tracker: any ScreenTracker
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .onAppear { tracker.screenDidAppear(envelope, id: id) }
            .onDisappear { tracker.screenDidDisappear(id: id) }
    }
}
