import SwiftUI

/// The dev tools window's content: the pill, centered just below the status
/// bar, and the menu it opens on a long press.
struct DevToolsOverlay: View {
    let devTools: DevTools
    let onPillFrame: (CGRect) -> Void
    @State private var isMenuPresented = false

    var body: some View {
        VStack {
            DevToolsPill(name: devTools.environment.name, isArmed: !devTools.registry.warnings.isEmpty)
                .background {
                    GeometryReader { proxy in
                        let frame = proxy.frame(in: .global)
                        Color.clear
                            .onAppear { onPillFrame(frame) }
                            .onChange(of: frame) { _, frame in onPillFrame(frame) }
                    }
                }
                .onLongPressGesture { isMenuPresented = true }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $isMenuPresented, onDismiss: devTools.menuDidClose) {
            DevToolsMenu(devTools: devTools)
        }
    }
}

/// The environment name, with an alert icon while a tool has armed a failure.
struct DevToolsPill: View {
    let name: String
    let isArmed: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.phDiagnostic)
                .textCase(.uppercase)
                .foregroundStyle(Color.phInk)
            if isArmed {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.devToolsWarning)
                    .accessibilityIdentifier("devTools.pill.armed")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.phSurfaceRaised))
        .overlay(Capsule().stroke(Color.phSky, lineWidth: 1.5))
        .contentShape(Capsule())
        // Stays small at the largest text sizes, so it never grows over the
        // navigation bar's controls.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("devTools.pill")
    }
}

/// The menu: armed warnings first, then the current screen's tools, then the
/// app tools.
struct DevToolsMenu: View {
    let devTools: DevTools
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let registry = devTools.registry
        let warnings = registry.warnings
        NavigationStack {
            List {
                if !warnings.isEmpty {
                    Section {
                        ForEach(warnings, id: \.self) { warning in
                            Label(warning, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.devToolsWarning)
                                .accessibilityIdentifier("devTools.warning")
                        }
                    }
                }
                ForEach(registry.tools(forScreen: devTools.tracker.current?.key)) { tool in
                    Section(tool.title) { tool.content }
                }
                ForEach(registry.appTools) { tool in
                    Section(tool.title) { tool.content }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.phSurface)
            .navigationTitle("\(devTools.environment.name) menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("devTools.done")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .tint(Color.phInk)
    }
}

extension Color {
    /// Armed failures in the pill and menu. Dev tools only, so not a brand token.
    static let devToolsWarning = Color(light: 0x8A5A00, dark: 0xF2C46B)
}
