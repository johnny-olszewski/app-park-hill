package app.parkhill.services.supabase

import io.github.jan.supabase.auth.user.UserSession
import java.io.File
import java.nio.file.Files
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Test

class EncryptedSessionManagerTest {
    /** Reversible and obviously not plain text, for checking what reaches the file. */
    private val cipher = object : SessionCipher {
        override fun encrypt(plain: ByteArray) = plain.map { (it.toInt() xor 0x5A).toByte() }.toByteArray()
        override fun decrypt(sealed: ByteArray) = encrypt(sealed)
    }
    private val file = File(Files.createTempDirectory("session").toFile(), "Session/session.bin")
    private val manager = EncryptedSessionManager(file, cipher)
    private val session = UserSession(accessToken = "access-secret", refreshToken = "refresh-secret", expiresIn = 3600, tokenType = "bearer", user = null)

    @Test
    fun savesAndLoadsTheSession() = runTest {
        manager.saveSession(session)
        val loaded = manager.loadSession()
        assertEquals("access-secret", loaded?.accessToken)
        assertEquals("refresh-secret", loaded?.refreshToken)
    }

    @Test
    fun theFileHoldsNoPlainToken() = runTest {
        manager.saveSession(session)
        val text = file.readBytes().decodeToString()
        assertFalse(text.contains("access-secret"))
        assertFalse(text.contains("refresh-secret"))
    }

    @Test
    fun deleteRemovesTheSession() = runTest {
        manager.saveSession(session)
        manager.deleteSession()
        assertNull(manager.loadSession())
        assertFalse(file.exists())
    }

    @Test
    fun anUnreadableFileIsNoSession() = runTest {
        file.parentFile?.mkdirs()
        file.writeText("garbage")
        assertNull(manager.loadSession())
    }
}
