import OSLog
import SwiftUI

/// What screens call when something tappable is tapped. Screens never
/// navigate: the tab coordinator supplies these through the environment and
/// performs the backend's action (guide 5.1).
struct ScreenActions {
    /// Hands back the people chosen in a screen opened with `open`, such as
    /// the people picker.
    typealias PeopleHandler = @MainActor ([PersonRow]) -> Void
    /// Makes a form's call with fields added and returns its body, or nil
    /// when it failed; `on_success` applies when the predicate says the body
    /// is a success.
    typealias SubmitHandler = @MainActor (CallAction, [String: JSONValue], ScreenModel?, @escaping (JSONValue) -> Bool) async -> JSONValue?

    var perform: @MainActor (Action) -> Void = { _ in }
    /// The coordinator's handler, given the screen each action came from and
    /// where to hand back chosen people.
    private var performFrom: (@MainActor (Action, ScreenModel?, PeopleHandler?) -> Void)?
    private var submitFrom: SubmitHandler?
    private var source: ScreenModel?

    init(perform: @escaping @MainActor (Action) -> Void = { _ in }) {
        self.perform = perform
    }

    /// A coordinator's actions: each is performed with the screen it came
    /// from, once `from(_:)` names it.
    init(coordinator: @escaping @MainActor (Action, ScreenModel?, PeopleHandler?) -> Void, submit: SubmitHandler? = nil) {
        perform = { coordinator($0, nil, nil) }
        performFrom = coordinator
        submitFrom = submit
    }

    /// These actions for `screen`'s content, so a `call` can refresh or
    /// dismiss the screen it came from.
    func from(_ screen: ScreenModel) -> ScreenActions {
        guard let performFrom else { return self }
        var actions = self
        actions.source = screen
        actions.perform = { performFrom($0, screen, nil) }
        return actions
    }

    /// Performs `action`, such as opening the people picker as a sheet, and
    /// hands the people chosen there to `onPeople`. Nothing is handed back
    /// when it is cancelled.
    @MainActor
    func open(_ action: Action, onPeople: @escaping PeopleHandler) {
        guard let performFrom else { return perform(action) }
        performFrom(action, source, onPeople)
    }

    /// Makes `call`, a form's submit such as edit mode's save, with `fields`
    /// added to its params, and returns the body. Its `on_success` applies to
    /// the screen these actions come from only when `succeeded` says so.
    /// Nil when the call failed; a refusal shows its message as any call's.
    @MainActor
    func submit(_ call: CallAction, adding fields: [String: JSONValue], succeeded: @escaping (JSONValue) -> Bool) async -> JSONValue? {
        await submitFrom?(call, fields, source, succeeded)
    }

    /// Whether this build knows the action's type. An unknown one makes its
    /// item not tappable (contract rule 3).
    func canPerform(_ action: Action) -> Bool {
        Self.isKnown(action)
    }

    /// True for action types this build performs; an unknown type is logged.
    static func isKnown(_ action: Action) -> Bool {
        switch action {
        case .navigate, .call:
            return true
        case .unknown(let type):
            Logger.navigation.error("Ignored action of unknown type \(type ?? "none", privacy: .public)")
            return false
        }
    }
}

/// What a screen shown as a sheet calls to finish: hand back the chosen
/// people and close, or close with nothing. The coordinator that presented
/// it supplies these.
struct SheetActions {
    var returnPeople: @MainActor ([PersonRow]) -> Void = { _ in }
    var cancel: @MainActor () -> Void = {}
}

extension EnvironmentValues {
    @Entry var screenActions = ScreenActions()
    @Entry var sheetActions = SheetActions()
}
