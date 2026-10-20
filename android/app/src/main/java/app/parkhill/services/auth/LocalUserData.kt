package app.parkhill.services.auth

import java.io.File

/**
 * Everything about the user stored on the device outside the session, which
 * the auth service deletes on every sign-out (specs/AUTH.md 4.4).
 */
class LocalUserData(private val directories: List<File>) {
    fun wipe() {
        directories.forEach { it.deleteRecursively() }
    }

    companion object {
        /** The cache directory (screens) and the user files directory. */
        fun standard(filesDir: File) = LocalUserData(listOf(File(filesDir, "Cache"), File(filesDir, "UserFiles")))
    }
}
