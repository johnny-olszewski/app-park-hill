package app.parkhill.services.backend

import app.parkhill.environment.AppEnvironment

/**
 * Labels sent on every backend request (specs/AUTH.md 5.6). For logging and
 * diagnostics only; the backend never uses them for access decisions.
 */
object StandardHeaders {
    fun make(environment: AppEnvironment, versionName: String, versionCode: Int, language: String): Map<String, String> =
        mapOf(
            "X-App-Config" to environment.name.lowercase(),
            "X-App-Platform" to "android",
            "X-App-Version" to "$versionName ($versionCode)",
            "Accept-Language" to language,
        )
}
