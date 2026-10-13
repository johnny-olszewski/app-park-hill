import SwiftUI
import UIKit

/// Park Hill design tokens (wireframes, guide 5.5): brand color and type
/// applied to system components. Every color adapts to light and dark mode.
extension Color {
    static let phSurface = Color(light: 0xFDFBF7, dark: 0x221F20)
    static let phSurfaceRaised = Color(light: 0xFFFFFF, dark: 0x2E2A2B)
    static let phSurfaceSunken = Color(light: 0xF4F0E8, dark: 0x191718)
    static let phInk = Color(light: 0x221F20, dark: 0xFDFBF7)
    static let phInkMuted = Color(light: 0x5F6769, dark: 0xA9B0B2)
    static let phLine = Color(light: 0xCCCCCC, dark: 0x4A4546)
    /// Filled buttons and selected states.
    static let phFill = Color(light: 0x221F20, dark: 0xFDFBF7)
    static let phOnFill = Color(light: 0xFDFBF7, dark: 0x221F20)
    static let phSky = Color(light: 0xA0C6DC, dark: 0xA0C6DC)
    static let phDanger = Color(light: 0xB3261E, dark: 0xFF9485)

    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Font {
    /// Screen and section headings: the brand serif.
    static let phHeading = Font.system(.title2, design: .serif)
    /// Small uppercase labels above fields and lists.
    static let phLabel = Font.caption2.weight(.semibold)
    /// The backend-target label.
    static let phDiagnostic = Font.system(.caption2, design: .monospaced).weight(.semibold)
}

enum Theme {
    /// Navigation bar titles in the brand serif, app-wide. Call once at launch.
    @MainActor
    static func applyNavigationBarAppearance() {
        let ink = UIColor(Color.phInk)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(Color.phSurface)
        appearance.largeTitleTextAttributes = [
            .font: serif(size: 34, weight: .regular),
            .foregroundColor: ink,
        ]
        appearance.titleTextAttributes = [
            .font: serif(size: 19, weight: .medium),
            .foregroundColor: ink,
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    private static func serif(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}

/// Full-width primary button: filled ink with uppercase, tracked label.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.semibold))
            .tracking(1.2)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isEnabled ? Color.phOnFill : Color.phInkMuted)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isEnabled ? Color.phFill : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isEnabled ? Color.phFill : Color.phInkMuted, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Outlined button that sizes to its label, for secondary actions like
/// retry. Destructive buttons use the danger color.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let color = configuration.role == .destructive ? Color.phDanger : Color.phInk
        return configuration.label
            .font(.footnote.weight(.semibold))
            .tracking(1.2)
            .textCase(.uppercase)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .foregroundStyle(color)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color, lineWidth: 2))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// System text field with the brand's rounded, bordered look.
struct BrandFieldModifier: ViewModifier {
    var isInvalid = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .frame(minHeight: 42)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.phSurfaceRaised))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isInvalid ? Color.phDanger : Color.phInkMuted, lineWidth: 2)
            )
    }
}

extension View {
    func brandField(isInvalid: Bool = false) -> some View {
        modifier(BrandFieldModifier(isInvalid: isInvalid))
    }

    /// The small uppercase label style used above fields and lists.
    func brandLabel() -> some View {
        font(.phLabel).tracking(0.7).textCase(.uppercase).foregroundStyle(Color.phInk)
    }
}

/// Backend-target label at the bottom of entry screens (non-release builds).
struct BackendTargetLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.phDiagnostic)
            .textCase(.uppercase)
            .foregroundStyle(Color.phInkMuted)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("backendTargetLabel")
    }
}
