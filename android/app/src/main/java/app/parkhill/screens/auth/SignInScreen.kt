package app.parkhill.screens.auth

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.autofill.ContentType
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.contentType
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.parkhill.contract.SignInScreenData
import app.parkhill.design.ParkHill
import app.parkhill.design.PrimaryButton
import app.parkhill.design.brandFieldColors
import app.parkhill.services.auth.AuthService
import app.parkhill.services.auth.SignInError
import kotlinx.coroutines.launch

/**
 * True when the user was signed out because access ended, so the sign-in
 * screen shows `session_ended_message`. Provided by the app root.
 */
val LocalSessionEndedNotice = compositionLocalOf { false }

/**
 * Signs in through [AuthService] and holds what the screen shows. A
 * successful sign-in changes the auth state, which the app coordinator
 * follows; the screen never navigates.
 */
class SignInModel(val data: SignInScreenData, private val auth: AuthService) {
    var email by mutableStateOf("")
    var password by mutableStateOf("")
    var isSubmitting by mutableStateOf(false)
        private set

    /** The backend's refusal for the last attempt, shown under the password. */
    var errorMessage by mutableStateOf<String?>(null)
        private set

    /** `cannot_connect_message` after an attempt that got no usable answer, shown in the message box. */
    var connectionMessage by mutableStateOf<String?>(null)
        private set

    var hasAttempted by mutableStateOf(false)
        private set

    val canSubmit: Boolean get() = email.isNotBlank() && password.isNotEmpty() && !isSubmitting

    suspend fun submit() {
        if (!canSubmit) return
        isSubmitting = true
        hasAttempted = true
        errorMessage = null
        connectionMessage = null
        try {
            auth.signIn(email.trim(), password)
            password = ""
        } catch (error: SignInError.Rejected) {
            errorMessage = error.message
        } catch (_: SignInError) {
            connectionMessage = data.cannotConnectMessage
        } finally {
            isSubmitting = false
        }
    }
}

/** `auth.sign_in`: email and password in Material fields with the brand style. All text comes from the screen data. */
@Composable
fun SignInScreen(data: SignInScreenData, auth: AuthService) {
    val model = remember(data) { SignInModel(data, auth) }
    val scope = rememberCoroutineScope()
    val focus = LocalFocusManager.current
    val colors = ParkHill.colors
    val sessionEnded = LocalSessionEndedNotice.current
    val boxMessage = model.connectionMessage ?: data.sessionEndedMessage.takeIf { sessionEnded && !model.hasAttempted }
    fun submit() {
        focus.clearFocus()
        scope.launch { model.submit() }
    }

    Column(
        Modifier.fillMaxSize().background(colors.surface).safeDrawingPadding().imePadding()
            .verticalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Text(data.title, style = ParkHill.heading, color = colors.ink, modifier = Modifier.padding(top = 16.dp).testTag("signIn.title"))

        boxMessage?.let {
            Text(
                it,
                fontSize = 13.sp,
                color = colors.ink,
                modifier = Modifier.fillMaxWidth()
                    .background(colors.surfaceSunken, ParkHill.shape)
                    .border(BorderStroke(1.dp, colors.line), ParkHill.shape)
                    .padding(horizontal = 12.dp, vertical = 10.dp)
                    .testTag("signIn.notice"),
            )
        }

        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(data.emailLabel.uppercase(), style = ParkHill.label, color = colors.ink)
            OutlinedTextField(
                value = model.email,
                onValueChange = { model.email = it },
                singleLine = true,
                shape = ParkHill.shape,
                colors = brandFieldColors(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email, imeAction = ImeAction.Next, autoCorrectEnabled = false),
                keyboardActions = KeyboardActions(onNext = { focus.moveFocus(FocusDirection.Down) }),
                modifier = Modifier.fillMaxWidth().testTag("signIn.email")
                    .semantics { contentType = ContentType.Username + ContentType.EmailAddress; contentDescription = data.emailLabel },
            )
        }

        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(data.passwordLabel.uppercase(), style = ParkHill.label, color = colors.ink)
            OutlinedTextField(
                value = model.password,
                onValueChange = { model.password = it },
                singleLine = true,
                isError = model.errorMessage != null,
                shape = ParkHill.shape,
                colors = brandFieldColors(),
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, imeAction = ImeAction.Go),
                keyboardActions = KeyboardActions(onGo = { submit() }),
                modifier = Modifier.fillMaxWidth().testTag("signIn.password")
                    .semantics { contentType = ContentType.Password; contentDescription = data.passwordLabel },
            )
            model.errorMessage?.let {
                Text(it, fontSize = 12.sp, color = colors.danger, modifier = Modifier.testTag("signIn.error"))
            }
        }

        PrimaryButton(
            text = data.submitLabel,
            onClick = ::submit,
            enabled = model.canSubmit,
            modifier = Modifier.testTag("signIn.submit"),
            leading = {
                if (model.isSubmitting) {
                    CircularProgressIndicator(color = colors.onFill, strokeWidth = 2.dp, modifier = Modifier.size(16.dp).padding(end = 0.dp))
                }
            },
        )
    }
}
