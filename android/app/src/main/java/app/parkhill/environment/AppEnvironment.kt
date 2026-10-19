package app.parkhill.environment

/**
 * The environment this build targets. Each flavor's `ServiceBinding` declares
 * exactly one value (guide 5.2); app code never checks which.
 */
data class AppEnvironment(
    /** Flavor name, for example "Mock" or "Dev". */
    val name: String,
    /** The backend this build talks to, or null when it has none. */
    val backend: BackendTarget?,
) {
    /** Human-readable backend target, for the launch log and debug UI. */
    val backendLabel: String get() = backend?.url ?: "none"
}

/** A Supabase backend: API URL and anon key. */
data class BackendTarget(val url: String, val anonKey: String)
