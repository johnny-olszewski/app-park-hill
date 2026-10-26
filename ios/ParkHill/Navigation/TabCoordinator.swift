import Foundation
import Observation
import OSLog

/// One tab's navigation (guide 5.1): its root screen, the screens pushed over
/// it and the one presented as a sheet. Kept while the tab is switched away
/// from, so each tab returns to where it was. Also performs `call` actions
/// and the lost-access rule for every screen it shows (guide 5.3 rule 9).
@MainActor
@Observable
final class TabCoordinator: Identifiable {
    let id: String
    private(set) var title: String
    private(set) var iconKey: String
    let root: ScreenModel
    /// Screens pushed over the root, oldest first.
    var path: [Route] = []
    /// The screen presented as a sheet, if any.
    var presented: Route?
    /// The full-screen cover showing over the tab, if any.
    var cover: CoverCoordinator?
    /// A `call` waiting for the person to confirm it, with the backend's wording.
    var pendingCall: PendingCall?
    /// A backend message to show once, such as lost access or a refused call.
    var message: String?

    private let context: ScreenContext
    /// Counts lost-access closes, so a refused call can tell whether its
    /// refresh lost access too.
    @ObservationIgnored private var lostAccessCount = 0
    /// The refresh started after a screen closed, for tests to wait on.
    @ObservationIgnored private(set) var refresh: Task<Void, Never>?

    init(item: TabItem, context: ScreenContext) {
        id = item.id
        title = item.title
        iconKey = item.iconKey
        root = ScreenModel(envelope: item.screen, context: context)
        self.context = context
        root.onLostAccess = { [weak self] screen, message in self?.lostAccess(screen, message: message) }
    }

    /// Takes a refreshed title, icon and root screen for the same tab.
    func update(from item: TabItem) {
        title = item.title
        iconKey = item.iconKey
        root.update(item.screen)
    }

    /// What this tab's screens call when something is tapped.
    var actions: ScreenActions {
        ScreenActions(coordinator: { [weak self] action, source, onPeople in self?.perform(action, from: source, onPeople: onPeople) })
    }

    /// Performs a backend action: `navigate` with `push` fetches the target
    /// screen over a loading state on this tab's stack; with
    /// `full_screen_cover` it opens a cover whose root is fetched fresh; with
    /// `sheet` it presents the target as a sheet, handing what it returns to
    /// `onPeople`. A `call` asks for the backend's confirmation first when it
    /// has one. An unknown action, or a target this build does not register,
    /// does nothing and is logged.
    func perform(_ action: Action, from source: ScreenModel? = nil, onPeople: ScreenActions.PeopleHandler? = nil) {
        switch action {
        case .navigate(let navigate):
            switch navigate.presentation {
            case .push:
                guard let screen = context.target(of: navigate) else { return }
                screen.onLostAccess = lostAccessHandler
                path.append(Route(screen: screen))
                Task { await screen.load() }
            case .sheet:
                presentSheet(navigate, onPeople: onPeople)
            case .fullScreenCover:
                guard context.registry.isRegistered(navigate.screenKey) else {
                    _ = context.target(of: navigate)
                    return
                }
                let cover = CoverCoordinator(
                    key: navigate.screenKey,
                    params: navigate.params.objectValue,
                    context: context,
                    performCall: { [weak self] call, source in self?.performCall(call, from: source) },
                    presentSheet: { [weak self] navigate, onPeople in self?.presentSheet(navigate, onPeople: onPeople) },
                    lostAccess: lostAccessHandler
                )
                self.cover = cover
                Task { await cover.root.load() }
            }
        case .call(let call):
            performCall(call, from: source)
        case .unknown:
            _ = ScreenActions.isKnown(action)
        }
    }

    /// Presents `navigate`'s target as a sheet over a loading state, from the
    /// tab or from inside its cover. What the sheet returns goes to
    /// `onPeople`.
    func presentSheet(_ navigate: NavigateAction, onPeople: ScreenActions.PeopleHandler?) {
        guard let screen = context.target(of: navigate) else { return }
        screen.onLostAccess = lostAccessHandler
        presented = Route(screen: screen, onPeople: onPeople)
        Task { await screen.load() }
    }

    /// The sheet's people were chosen: close it and hand them to its opener.
    func returnPeople(_ people: [PersonRow]) {
        let onPeople = presented?.onPeople
        presented = nil
        onPeople?(people)
    }

    /// Asks to confirm `call` when it carries a confirmation, else makes it.
    func performCall(_ call: CallAction, from source: ScreenModel?) {
        if let confirm = call.confirm {
            pendingCall = PendingCall(call: call, confirm: confirm, source: source)
        } else {
            Task { await run(call, from: source) }
        }
    }

    /// The person confirmed: make the call.
    func confirm(_ pending: PendingCall) {
        pendingCall = nil
        Task { await run(pending.call, from: pending.source) }
    }

    /// The person cancelled: nothing is called.
    func cancelCall() {
        pendingCall = nil
    }

    /// Makes `call`, then applies its `on_success` to the screen it came
    /// from. A refusal refreshes that screen and shows the backend's message,
    /// unless the refresh lost access, whose message is shown instead.
    func run(_ call: CallAction, from source: ScreenModel?) async {
        do {
            try await context.backend.call(function: call.function, params: call.params.objectValue, locale: context.locale())
        } catch .actionRefused(let refusal) {
            let count = lostAccessCount
            await source?.load()
            if lostAccessCount == count { message = refusal }
            return
        } catch {
            Logger.navigation.error("\(call.function, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            return
        }
        switch call.onSuccess {
        case .refresh:
            await source?.load()
        case .dismiss:
            guard let source else { return }
            if let below = close(source) {
                await below.load()
            } else {
                await source.load()
            }
        case .none:
            break
        }
    }

    /// The lost-access rule: closes `screen`, refreshes the screen below and
    /// shows the backend's message. A tab root stays, with the message.
    func lostAccess(_ screen: ScreenModel, message: String) {
        lostAccessCount += 1
        if let below = close(screen) {
            refresh = Task { await below.load() }
        }
        self.message = message
    }

    private var lostAccessHandler: @MainActor (ScreenModel, String) -> Void {
        { [weak self] screen, message in self?.lostAccess(screen, message: message) }
    }

    /// Closes `screen` with everything over it, wherever this tab shows it,
    /// and returns the screen now under it. Nil for the tab root, which
    /// cannot close.
    private func close(_ screen: ScreenModel) -> ScreenModel? {
        if let cover, cover.contains(screen) {
            if let below = cover.close(screen) { return below }
            self.cover = nil
            return path.last?.screen ?? root
        }
        if presented?.screen === screen {
            presented = nil
            return path.last?.screen ?? root
        }
        guard let index = path.firstIndex(where: { $0.screen === screen }) else { return nil }
        path.removeSubrange(index...)
        return path.last?.screen ?? root
    }

    /// Closes the full-screen cover, dropping its stack and screens.
    func closeCover() {
        cover = nil
    }

    /// Pushes the screen for `envelope`. False, and logged by the registry,
    /// when this build cannot show it.
    @discardableResult
    func push(_ envelope: ScreenEnvelope) -> Bool {
        guard context.registry.resolve(envelope) != nil else { return false }
        let screen = ScreenModel(envelope: envelope, context: context)
        screen.onLostAccess = lostAccessHandler
        path.append(Route(screen: screen))
        return true
    }

    /// Presents the screen for `envelope` as a sheet. False when this build
    /// cannot show it.
    @discardableResult
    func present(_ envelope: ScreenEnvelope) -> Bool {
        guard context.registry.resolve(envelope) != nil else { return false }
        let screen = ScreenModel(envelope: envelope, context: context)
        screen.onLostAccess = lostAccessHandler
        presented = Route(screen: screen)
        return true
    }

    func pop() {
        _ = path.popLast()
    }

    func dismiss() {
        presented = nil
    }
}

/// A `call` waiting for confirmation, with the screen it came from.
struct PendingCall: Identifiable {
    let id = UUID()
    let call: CallAction
    let confirm: CallConfirmation
    let source: ScreenModel?

    var isDestructive: Bool { call.role == .destructive }
}

/// One shown screen in a tab's stack or sheet. Identity is per showing, so
/// the same screen key can appear twice.
struct Route: Identifiable, Hashable {
    let id = UUID()
    let screen: ScreenModel
    /// Where a sheet hands back the people chosen in it, if anywhere.
    var onPeople: ScreenActions.PeopleHandler?

    static func == (lhs: Route, rhs: Route) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension JSONValue {
    /// The members of an object; empty for any other value.
    var objectValue: [String: JSONValue] {
        if case .object(let members) = self { return members }
        return [:]
    }
}
