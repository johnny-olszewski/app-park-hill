package app.parkhill.app

import android.content.Context
import app.parkhill.environment.AppAuthService
import app.parkhill.environment.AppBackendService
import app.parkhill.environment.AppEnvironment
import app.parkhill.services.auth.SessionRenewingBackendService
import app.parkhill.services.backend.BackendService

/**
 * Composition root. Constructs the services this flavor's binding declares;
 * never checks which flavor it is.
 */
class AppServices(context: Context, val environment: AppEnvironment) {
    /** The concrete type, so the mock binding can reach mock-only sign-in. */
    val auth: AppAuthService = AppAuthService(context.applicationContext, environment)

    /** Backend calls with the unauthorized rule applied: one renewal and retry, then sign-out. */
    val backend: BackendService = SessionRenewingBackendService(AppBackendService(context.applicationContext, environment), auth)
}
