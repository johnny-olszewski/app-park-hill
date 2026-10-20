package app.parkhill.screens.auth

import app.parkhill.navigation.StubBackendService
import app.parkhill.services.auth.FakeAuthService
import app.parkhill.services.auth.SignInError
import app.parkhill.services.backend.ContractJson
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class SignInModelTest {
    private val auth = FakeAuthService()
    private val data = ContractJson.decodeFromJsonElement(SignInScreenData.serializer(), StubBackendService.signIn().data)
    private val model = SignInModel(data, auth).apply {
        email = " attendee@parkhill.test "
        password = "secret"
    }

    @Test
    fun cannotSubmitWithAnEmptyField() {
        model.password = ""
        assertFalse(model.canSubmit)
    }

    @Test
    fun aSuccessfulSignInClearsThePassword() = runTest {
        model.submit()
        assertEquals(1, auth.signIns)
        assertEquals("", model.password)
        assertNull(model.errorMessage)
    }

    @Test
    fun aRefusalShowsTheBackendsMessageUnderThePassword() = runTest {
        auth.signInFailure = SignInError.Rejected("invalid_credentials", "That email and password don't match.")
        model.submit()
        assertEquals("That email and password don't match.", model.errorMessage)
        assertNull(model.connectionMessage)
        assertTrue(model.hasAttempted)
    }

    @Test
    fun noUsableAnswerShowsTheCannotConnectMessage() = runTest {
        for (failure in listOf(SignInError.Network, SignInError.Unexpected)) {
            auth.signInFailure = failure
            model.submit()
            assertEquals("Can't connect.", model.connectionMessage)
            assertNull(model.errorMessage)
        }
    }
}
