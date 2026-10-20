package app.parkhill.app

import java.util.Locale

/**
 * The locale sent as `p_locale` on every backend call: the device's language
 * code, for example "en". The backend falls back to English.
 */
object AppLocale {
    fun current(locale: Locale = Locale.getDefault()): String = locale.language.ifEmpty { "en" }
}
