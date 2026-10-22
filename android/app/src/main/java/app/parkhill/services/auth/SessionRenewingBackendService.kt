package app.parkhill.services.auth

import app.parkhill.services.backend.BackendError
import app.parkhill.services.backend.BackendService
import app.parkhill.services.backend.Profile
import app.parkhill.services.backend.ScreenEnvelope
import app.parkhill.services.backend.TabsResponse
import kotlinx.serialization.json.JsonObject

/**
 * Wraps a [BackendService] with the unauthorized rule (guide 5.3 rule 8,
 * specs/AUTH.md 4.3): a request refused as unauthorized gets one session
 * renewal and one retry; if either is refused, the session ends. Network
 * failures never sign anyone out.
 */
class SessionRenewingBackendService(
    private val base: BackendService,
    private val auth: AuthService,
) : BackendService {
    override suspend fun getEntry(locale: String) = withRenewal { base.getEntry(locale) }

    override suspend fun getScreen(key: String, locale: String, params: JsonObject): ScreenEnvelope =
        withRenewal { base.getScreen(key, locale, params) }

    override suspend fun getTabs(locale: String): TabsResponse = withRenewal { base.getTabs(locale) }

    override suspend fun whoami(): Profile = withRenewal { base.whoami() }

    private suspend fun <T> withRenewal(request: suspend () -> T): T = try {
        request()
    } catch (unauthorized: BackendError.Unauthorized) {
        when (auth.renewAfterUnauthorized()) {
            SessionRenewal.Renewed -> try {
                request()
            } catch (again: BackendError.Unauthorized) {
                auth.endSession()
                throw again
            }
            SessionRenewal.Network -> throw BackendError.Network
            SessionRenewal.Refused, SessionRenewal.NotSignedIn -> throw unauthorized
        }
    }
}
