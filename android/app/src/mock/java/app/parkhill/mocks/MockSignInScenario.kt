package app.parkhill.mocks

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

/** What the next mock sign-in does (specs/AUTH.md 5.4), chosen in the mock menu. */
enum class MockSignInResult(val title: String, val refusalFixture: String?) {
    Success("Success", null),
    InvalidCredentials("Wrong email or password", "sign_in.error"),
    AccountDisabled("Account disabled", "sign_in.error.account_disabled"),
    TooManyAttempts("Too many attempts", "sign_in.error.too_many_attempts"),
    InvalidRequest("Invalid request", "sign_in.error.invalid_request"),
    ServerError("Server error", "sign_in.error.unknown"),
    NoConnection("No connection", null),
    SomethingWentWrong("Something went wrong", null),
}

/**
 * The persona and next sign-in result chosen in the mock menu, for the
 * launch. Snapshot state, so the menu and pill update as choices change.
 */
class MockSignInScenario(val personas: List<MockPersona>) {
    /** Who Success signs in as: the first active persona until changed. */
    var persona: String by mutableStateOf(personas.first().id)

    var result: MockSignInResult by mutableStateOf(MockSignInResult.Success)
}
