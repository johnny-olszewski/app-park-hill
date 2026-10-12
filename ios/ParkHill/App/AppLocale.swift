import Foundation

/// The locale sent as `p_locale` on every backend call: the language code of
/// the device's preferred language, for example "en". The backend falls back to
/// English for anything it has not seeded.
enum AppLocale {
    static func current(preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        guard let first = preferredLanguages.first,
              let code = Locale(identifier: first).language.languageCode?.identifier
        else { return "en" }
        return code
    }
}
