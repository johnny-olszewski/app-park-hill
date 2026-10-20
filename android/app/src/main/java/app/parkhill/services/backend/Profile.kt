package app.parkhill.services.backend

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** The signed-in caller's profile (`whoami`, contract/README.md). */
@Serializable
data class Profile(val id: String, @SerialName("display_name") val displayName: String)
