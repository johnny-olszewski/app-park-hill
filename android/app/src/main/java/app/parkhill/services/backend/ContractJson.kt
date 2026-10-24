package app.parkhill.services.backend

import kotlinx.serialization.json.Json

/**
 * Contract JSON: unknown fields are ignored (guide 4.1 rule 2). Every response
 * decodes into a generated type from app.parkhill.contract with it.
 */
val ContractJson = Json { ignoreUnknownKeys = true }
