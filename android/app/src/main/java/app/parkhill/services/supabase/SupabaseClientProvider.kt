package app.parkhill.services.supabase

import app.parkhill.BuildConfig
import app.parkhill.app.AppLocale
import app.parkhill.environment.AppEnvironment
import app.parkhill.services.backend.StandardHeaders
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import io.ktor.client.engine.okhttp.OkHttp
import okhttp3.Interceptor

/**
 * The one Supabase client the app shares (guide 5.1): backend calls now, auth
 * later (AND-005), so signed-in calls carry the session automatically.
 */
object SupabaseClientProvider {
    @Volatile private var shared: SupabaseClient? = null

    fun client(environment: AppEnvironment): SupabaseClient =
        shared ?: synchronized(this) { shared ?: make(environment).also { shared = it } }

    /**
     * A client for `environment` whose every request carries the standard
     * headers, added on the HTTP engine (supabase-kt has no public header
     * option).
     */
    fun make(environment: AppEnvironment): SupabaseClient {
        val backend = checkNotNull(environment.backend) { "${environment.name} has no backend" }
        val headers = StandardHeaders.make(environment, BuildConfig.VERSION_NAME, BuildConfig.VERSION_CODE, AppLocale.current())
        return createSupabaseClient(backend.url, backend.anonKey) {
            httpEngine = OkHttp.create { addInterceptor(standardHeaders(headers)) }
            install(Postgrest)
        }
    }

    private fun standardHeaders(headers: Map<String, String>) = Interceptor { chain ->
        val request = chain.request().newBuilder()
        headers.forEach { (name, value) -> request.header(name, value) }
        chain.proceed(request.build())
    }
}
