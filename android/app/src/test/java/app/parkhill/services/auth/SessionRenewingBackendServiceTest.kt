package app.parkhill.services.auth

import app.parkhill.contract.Profile
import app.parkhill.navigation.StubBackendService
import app.parkhill.services.backend.BackendError
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import org.junit.Test

class SessionRenewingBackendServiceTest {
    private val backend = StubBackendService { StubBackendService.signIn() }
    private val auth = FakeAuthService()
    private val service = SessionRenewingBackendService(backend, auth)

    private suspend fun expect(expected: BackendError) {
        try {
            service.whoami()
            fail("expected $expected")
        } catch (error: BackendError) {
            assertEquals(expected, error)
        }
    }

    @Test
    fun aSuccessfulRequestIsPassedThrough() = runTest {
        assertEquals(Profile("u", "User"), service.whoami())
        assertEquals(0, auth.renewals)
    }

    @Test
    fun unauthorizedRenewsOnceAndRetries() = runTest {
        var calls = 0
        backend.profile = { if (calls++ == 0) throw BackendError.Unauthorized else Profile("u", "User") }
        assertEquals(Profile("u", "User"), service.whoami())
        assertEquals(1, auth.renewals)
        assertEquals(0, auth.endedSessions)
    }

    @Test
    fun aCallRefusedAsUnauthorizedRenewsAndRetries() = runTest {
        var calls = 0
        backend.callResult = { if (calls++ == 0) throw BackendError.Unauthorized }
        service.call("leave_group", JsonObject(emptyMap()), "en")
        assertEquals(2, backend.calls.size)
        assertEquals(1, auth.renewals)
    }

    @Test
    fun aRetryRefusedAgainEndsTheSession() = runTest {
        backend.profile = { throw BackendError.Unauthorized }
        expect(BackendError.Unauthorized)
        assertEquals(1, auth.renewals)
        assertEquals(1, auth.endedSessions)
        assertEquals(2, backend.whoamiCalls)
    }

    @Test
    fun aRefusedRenewalDoesNotRetry() = runTest {
        auth.renewal = SessionRenewal.Refused
        backend.profile = { throw BackendError.Unauthorized }
        expect(BackendError.Unauthorized)
        assertEquals(1, backend.whoamiCalls)
    }

    @Test
    fun aRenewalWithNoNetworkIsANetworkError() = runTest {
        auth.renewal = SessionRenewal.Network
        backend.profile = { throw BackendError.Unauthorized }
        expect(BackendError.Network)
        assertEquals(0, auth.endedSessions)
    }

    @Test
    fun networkErrorsNeverRenewOrSignOut() = runTest {
        backend.profile = { throw BackendError.Network }
        expect(BackendError.Network)
        assertEquals(0, auth.renewals)
        assertEquals(0, auth.endedSessions)
    }
}
