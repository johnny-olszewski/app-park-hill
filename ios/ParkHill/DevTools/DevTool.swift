import SwiftUI

/// One section of the dev tools menu: a title and its rows. A tool may report
/// a warning while it has armed something other than the normal result (for
/// example a sign-in that will fail); the pill and menu then show it.
@MainActor
struct DevTool: Identifiable {
    let id: String
    let title: String
    private let warningText: @MainActor () -> String?
    private let makeContent: @MainActor () -> AnyView

    init<Content: View>(
        id: String,
        title: String,
        warning: @escaping @MainActor () -> String? = { nil },
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) {
        self.id = id
        self.title = title
        self.warningText = warning
        self.makeContent = { AnyView(content()) }
    }

    /// Read while the menu or pill renders, so state the tool observes updates them.
    var warning: String? { warningText() }

    var content: AnyView { makeContent() }
}

/// The tools the menu offers: each screen's own, by screen key, then the
/// app-wide ones. Adding a tool is registering one entry; screens never know.
@MainActor
struct DevToolRegistry {
    private(set) var appTools: [DevTool] = []
    private var screenTools: [String: [DevTool]] = [:]

    mutating func register(_ tool: DevTool, forScreen key: String) {
        screenTools[key, default: []].append(tool)
    }

    mutating func registerAppTool(_ tool: DevTool) {
        appTools.append(tool)
    }

    /// The tools for the screen with `key`, in registration order.
    func tools(forScreen key: String?) -> [DevTool] {
        key.flatMap { screenTools[$0] } ?? []
    }

    /// Every armed warning, from any screen's tools or the app tools, so an
    /// armed failure is visible wherever the user is.
    var warnings: [String] {
        (screenTools.values.flatMap { $0 } + appTools).compactMap(\.warning).sorted()
    }
}
