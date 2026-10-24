package app.parkhill.services

import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.environment.ServiceBinding
import app.parkhill.services.supabase.SupabaseBackendService
import app.parkhill.services.supabase.SupabaseClientProvider
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith

/** Dev against the configured backend (local Supabase by default): start it first, see README. */
@RunWith(AndroidJUnit4::class)
class SupabaseBackendIntegrationTest {
    @Test
    fun getEntryReturnsTheSignInEnvelope() = runTest {
        val service = SupabaseBackendService(SupabaseClientProvider.make(ServiceBinding.environment))
        assertEquals("auth.sign_in", service.getEntry("en").key)
    }
}
