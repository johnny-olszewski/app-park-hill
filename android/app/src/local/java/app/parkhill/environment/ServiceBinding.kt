// Compiled only in the local flavor (src/local).
package app.parkhill.environment

import app.parkhill.BuildConfig
import app.parkhill.app.AppServices
import app.parkhill.navigation.ScreenRegistry
import app.parkhill.navigation.ScreenTracker
import app.parkhill.navigation.registerSharedScreens
import app.parkhill.services.supabase.SupabaseAuthService
import app.parkhill.services.supabase.SupabaseBackendService

typealias AppBackendService = SupabaseBackendService
typealias AppAuthService = SupabaseAuthService

object ServiceBinding {
    /** Local Supabase by default; local.override.properties overrides it (README). */
    val environment = AppEnvironment(
        name = "Local",
        backend = BackendTarget(url = BuildConfig.BACKEND_URL, anonKey = BuildConfig.BACKEND_ANON_KEY),
    )

    /** The screens this flavor registers. */
    fun makeScreenRegistry(services: AppServices, tracker: ScreenTracker?): ScreenRegistry =
        ScreenRegistry(tracker).apply { registerSharedScreens(services.auth) }
}
