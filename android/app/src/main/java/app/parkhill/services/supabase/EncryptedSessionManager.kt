package app.parkhill.services.supabase

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.github.jan.supabase.auth.SessionManager
import io.github.jan.supabase.auth.user.UserSession
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import kotlinx.serialization.json.Json

/**
 * Stores the Supabase session encrypted (AND-005 AC2): supabase-kt's default
 * storage is not. The session never touches plain SharedPreferences.
 */
class EncryptedSessionManager(private val file: File, private val cipher: SessionCipher) : SessionManager {
    override suspend fun saveSession(session: UserSession) {
        file.parentFile?.mkdirs()
        val temporary = File(file.parentFile, "${file.name}.tmp")
        temporary.writeBytes(cipher.encrypt(json.encodeToString(UserSession.serializer(), session).encodeToByteArray()))
        check(temporary.renameTo(file)) { "Could not write the session" }
    }

    override suspend fun loadSession(): UserSession? = try {
        file.takeIf { it.isFile }?.let { json.decodeFromString(UserSession.serializer(), cipher.decrypt(it.readBytes()).decodeToString()) }
    } catch (_: Exception) {
        // Unreadable (for example the key was lost): no session.
        null
    }

    override suspend fun deleteSession() {
        file.delete()
    }

    private companion object {
        val json = Json { ignoreUnknownKeys = true }
    }
}

/** Encrypts the session at rest. */
interface SessionCipher {
    fun encrypt(plain: ByteArray): ByteArray
    fun decrypt(sealed: ByteArray): ByteArray
}

/** AES-GCM with a key that never leaves the Android Keystore. */
class KeystoreSessionCipher(private val alias: String = "park_hill_session") : SessionCipher {
    override fun encrypt(plain: ByteArray): ByteArray {
        val cipher = Cipher.getInstance(TRANSFORMATION).apply { init(Cipher.ENCRYPT_MODE, key()) }
        return cipher.iv + cipher.doFinal(plain)
    }

    override fun decrypt(sealed: ByteArray): ByteArray {
        val iv = sealed.copyOfRange(0, IV_BYTES)
        val cipher = Cipher.getInstance(TRANSFORMATION).apply { init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, iv)) }
        return cipher.doFinal(sealed, IV_BYTES, sealed.size - IV_BYTES)
    }

    private fun key(): SecretKey {
        val store = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE).apply {
            init(
                KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setKeySize(256)
                    .build(),
            )
        }.generateKey()
    }

    private companion object {
        const val KEYSTORE = "AndroidKeyStore"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val IV_BYTES = 12
    }
}
