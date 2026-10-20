package app.parkhill.services.auth

import java.io.File
import java.nio.file.Files
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LocalUserDataTest {
    @Test
    fun wipeDeletesTheCacheAndUserFilesButNotTheRest() {
        val filesDir = Files.createTempDirectory("files").toFile()
        File(filesDir, "Cache/entry").mkdirs()
        File(filesDir, "Cache/entry/en.json").writeText("{}")
        File(filesDir, "UserFiles").mkdirs()
        File(filesDir, "UserFiles/photo.jpg").writeText("x")
        File(filesDir, "Other").mkdirs()

        LocalUserData.standard(filesDir).wipe()

        assertFalse(File(filesDir, "Cache").exists())
        assertFalse(File(filesDir, "UserFiles").exists())
        assertTrue(File(filesDir, "Other").exists())
    }
}
