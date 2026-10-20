package app.parkhill.mocks

import android.content.Context
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/** A persona the mock build can sign in as. */
data class MockPersona(val id: String, val displayName: String, val description: String) {
    companion object {
        /** The active personas in `contract/seed/dataset.json`, in dataset order. */
        fun active(datasetJson: String): List<MockPersona> =
            json.decodeFromString(Dataset.serializer(), datasetJson).personas
                .filter { it.state == "active" }
                .map { MockPersona(it.id, it.displayName, it.description) }

        /** The active personas in the dataset bundled with the mock build. */
        fun bundled(context: Context): List<MockPersona> =
            active(context.assets.open("dataset.json").bufferedReader().use { it.readText() })

        private val json = Json { ignoreUnknownKeys = true }
    }

    @Serializable
    private data class Dataset(val personas: List<Persona>) {
        @Serializable
        data class Persona(
            val id: String,
            @SerialName("display_name") val displayName: String,
            val description: String,
            val state: String,
        )
    }
}
