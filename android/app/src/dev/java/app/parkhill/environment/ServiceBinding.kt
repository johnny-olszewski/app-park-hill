// Compiled only in the dev flavor (src/dev).
package app.parkhill.environment

import app.parkhill.BuildConfig
import app.parkhill.app.AppServices
import app.parkhill.navigation.ScreenRegistry
import app.parkhill.navigation.registerSharedScreens
import app.parkhill.services.supabase.SupabaseAuthService
import app.parkhill.services.supabase.SupabaseBackendService

typealias AppBackendService = SupabaseBackendService
typealias AppAuthService = SupabaseAuthService

object ServiceBinding {
    /** Local Supabase by default; dev.local.properties overrides it (README). */
    val environment = AppEnvironment(
        name = "Dev",
        backend = BackendTarget(url = BuildConfig.BACKEND_URL, anonKey = BuildConfig.BACKEND_ANON_KEY),
    )

    /** The screens this flavor registers. */
    fun makeScreenRegistry(services: AppServices): ScreenRegistry =
        ScreenRegistry().apply { registerSharedScreens() }
}
