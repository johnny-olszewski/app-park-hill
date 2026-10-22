// Compiled only in mockDebug (src/mockDebug).
package app.parkhill.devtools

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.sp
import app.parkhill.app.AppServices
import app.parkhill.contract.ScreenKey
import app.parkhill.design.ParkHill
import app.parkhill.mocks.MockPersona
import app.parkhill.mocks.MockSignInResult
import app.parkhill.services.auth.AuthState

/**
 * The mock build's tools (specs/AUTH.md 5.4): who the next sign-in signs in
 * as and what it returns, on the sign-in screen; switching persona while
 * signed in, everywhere.
 */
fun DevTools.registerEnvironmentTools(services: AppServices) {
    val auth = services.auth
    val scenario = auth.scenario

    registry.register(
        DevTool(id = "mock.signIn.persona", title = "Sign in as") {
            PersonaRows(scenario.personas, selected = scenario.persona, tag = "mockSignIn.persona") { scenario.persona = it }
        },
        forScreen = SIGN_IN_SCREEN,
    )

    registry.register(
        DevTool(
            id = "mock.signIn.result",
            title = "Next sign-in",
            warningText = { scenario.result.takeIf { it != MockSignInResult.Success }?.let { "Next sign-in will fail: ${it.title}" } },
        ) {
            MockSignInResult.entries.forEach { result ->
                ToolCheckRow(
                    isSelected = scenario.result == result,
                    modifier = Modifier.testTag("mockSignIn.result.${result.name}"),
                    onClick = { scenario.result = result },
                ) { Text(result.title, color = ParkHill.colors.ink) }
            }
        },
        forScreen = SIGN_IN_SCREEN,
    )

    registry.registerAppTool(
        DevTool(id = "mock.switchPersona", title = "Switch persona") {
            val state by auth.state.collectAsState()
            val user = (state as? AuthState.SignedIn)?.user
            if (user != null) {
                PersonaRows(scenario.personas, selected = user.id, tag = "mockPersona") { auth.signIn(it) }
            } else {
                Text("Not signed in", color = ParkHill.colors.inkMuted)
            }
        },
    )
}

private const val SIGN_IN_SCREEN = ScreenKey.authSignIn

/** One row per persona, with a checkmark on the selected one. */
@Composable
private fun PersonaRows(personas: List<MockPersona>, selected: String?, tag: String, select: (String) -> Unit) {
    personas.forEach { persona ->
        ToolCheckRow(isSelected = persona.id == selected, modifier = Modifier.testTag("$tag.${persona.id}"), onClick = { select(persona.id) }) {
            Column {
                Text(persona.displayName, color = ParkHill.colors.ink)
                Text(persona.description, color = ParkHill.colors.inkMuted, fontSize = 12.sp)
            }
        }
    }
}
