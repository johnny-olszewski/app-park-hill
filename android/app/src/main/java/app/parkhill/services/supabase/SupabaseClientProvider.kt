package app.parkhill.services.supabase

import android.content.Context
import app.parkhill.BuildConfig
import app.parkhill.app.AppLocale
import app.parkhill.environment.AppEnvironment
import app.parkhill.services.backend.StandardHeaders
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.auth.MemoryCodeVerifierCache
import io.github.jan.supabase.auth.MemorySessionManager
import io.github.jan.supabase.auth.SessionManager
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import io.ktor.client.engine.okhttp.OkHttp
import java.io.File
import okhttp3.Interceptor
import okhttp3.OkHttpClient

/**
 * The one Supabase client the app shares (guide 5.1): backend calls and auth
 * use it, so signed-in calls carry the session automatically.
 */
object SupabaseClientProvider {
    @Volatile private var shared: Shared? = null

    /** The client and its pieces, made once per process. */
    class Shared(val client: SupabaseClient, val http: OkHttpClient, val sessions: SessionManager)

    fun shared(context: Context, environment: AppEnvironment): Shared =
        shared ?: synchronized(this) {
            shared ?: run {
                val sessions = EncryptedSessionManager(File(context.filesDir, "Session/session.bin"), KeystoreSessionCipher())
                val http = httpClient(environment)
                Shared(make(environment, sessions, http, lifecycleCallbacks = true), http, sessions).also { shared = it }
            }
        }

    /**
     * A client for `environment` whose every request carries the standard
     * headers, added on the HTTP engine (supabase-kt has no public header
     * option).
     */
    fun make(
        environment: AppEnvironment,
        sessions: SessionManager = MemorySessionManager(),
        http: OkHttpClient = httpClient(environment),
        lifecycleCallbacks: Boolean = false,
    ): SupabaseClient {
        val backend = checkNotNull(environment.backend) { "${environment.name} has no backend" }
        return createSupabaseClient(backend.url, backend.anonKey) {
            httpEngine = OkHttp.create { preconfigured = http }
            install(Postgrest)
            install(Auth) {
                sessionManager = sessions
                // Only for OAuth and magic links, which the app does not use; the
                // default needs Android preferences, unavailable in JVM tests.
                codeVerifierCache = MemoryCodeVerifierCache()
                autoLoadFromStorage = true
                autoSaveToStorage = true
                alwaysAutoRefresh = true
                enableLifecycleCallbacks = lifecycleCallbacks
            }
        }
    }

    /** OkHttp with the standard headers on every request. */
    fun httpClient(environment: AppEnvironment): OkHttpClient {
        val headers = StandardHeaders.make(environment, BuildConfig.VERSION_NAME, BuildConfig.VERSION_CODE, AppLocale.current())
        return OkHttpClient.Builder().addInterceptor(standardHeaders(headers)).build()
    }

    private fun standardHeaders(headers: Map<String, String>) = Interceptor { chain ->
        val request = chain.request().newBuilder()
        headers.forEach { (name, value) -> request.header(name, value) }
        chain.proceed(request.build())
    }
}
