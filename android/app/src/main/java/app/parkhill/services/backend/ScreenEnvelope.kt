package app.parkhill.services.backend

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject

/**
 * The one shape for any screen's content (contract/README.md). `data` stays
 * raw JSON here; the screen registry decodes it into the screen's own model.
 */
@Serializable
data class ScreenEnvelope(val key: String, val data: JsonObject)

/** Contract JSON: unknown fields are ignored (guide 4.1 rule 2). */
val ContractJson = Json { ignoreUnknownKeys = true }
