// Compiled only in the dev flavor (src/dev).
package app.parkhill.environment

import app.parkhill.BuildConfig
import app.parkhill.services.supabase.SupabaseBackendService

typealias AppBackendService = SupabaseBackendService

object ServiceBinding {
    /** Local Supabase by default; dev.local.properties overrides it (README). */
    val environment = AppEnvironment(
        name = "Dev",
        backend = BackendTarget(url = BuildConfig.BACKEND_URL, anonKey = BuildConfig.BACKEND_ANON_KEY),
    )
}
