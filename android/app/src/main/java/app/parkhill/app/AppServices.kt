package app.parkhill.app

import android.content.Context
import app.parkhill.environment.AppBackendService
import app.parkhill.environment.AppEnvironment
import app.parkhill.services.backend.BackendService

/**
 * Composition root. Constructs the services this flavor's binding declares;
 * never checks which flavor it is.
 */
class AppServices(context: Context, val environment: AppEnvironment) {
    val backend: BackendService = AppBackendService(context.applicationContext, environment)
}
