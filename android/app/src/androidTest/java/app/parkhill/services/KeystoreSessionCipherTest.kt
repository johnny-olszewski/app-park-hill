package app.parkhill.services

import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.services.supabase.KeystoreSessionCipher
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertFalse
import org.junit.Test
import org.junit.runner.RunWith

/** The real Android Keystore: sessions are encrypted at rest and come back intact. */
@RunWith(AndroidJUnit4::class)
class KeystoreSessionCipherTest {
    @Test
    fun encryptsAndDecrypts() {
        val cipher = KeystoreSessionCipher(alias = "park_hill_session_test")
        val plain = """{"access_token": "secret"}""".encodeToByteArray()
        val sealed = cipher.encrypt(plain)
        assertFalse(sealed.decodeToString().contains("secret"))
        assertArrayEquals(plain, cipher.decrypt(sealed))
    }
}
