import Observation
import SwiftUI

/// Signs in through `AuthService` and holds what the screen shows. A
/// successful sign-in changes the auth state, which the app coordinator
/// follows; the screen never navigates.
@MainActor
@Observable
final class SignInViewModel {
    var email = ""
    var password = ""
    private(set) var isSubmitting = false
    /// The backend's refusal for the last attempt, shown under the password.
    private(set) var errorMessage: String?
    /// `cannot_connect_message` after an attempt that got no usable answer,
    /// shown in the message box.
    private(set) var connectionMessage: String?
    private(set) var hasAttempted = false

    let data: SignInScreenData
    private let auth: any AuthService

    init(data: SignInScreenData, auth: any AuthService) {
        self.data = data
        self.auth = auth
    }

    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !isSubmitting
    }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        hasAttempted = true
        errorMessage = nil
        connectionMessage = nil
        defer { isSubmitting = false }
        do {
            _ = try await auth.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
            password = ""
        } catch {
            switch error {
            case .rejected(_, let message):
                errorMessage = message
            case .network, .unexpected:
                connectionMessage = data.cannotConnectMessage
            }
        }
    }
}

/// `auth.sign_in`: email and password with system fields in the brand style.
/// All text comes from the screen data.
struct SignInScreen: View {
    @State private var model: SignInViewModel
    @Environment(\.sessionEndedNotice) private var sessionEndedNotice
    @FocusState private var focus: Field?

    private enum Field {
        case email, password
    }

    init(data: SignInScreenData, auth: any AuthService) {
        _model = State(initialValue: SignInViewModel(data: data, auth: auth))
    }

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let boxMessage {
                        Text(boxMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.phInk)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.phSurfaceSunken))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.phLine))
                            .accessibilityIdentifier("signIn.notice")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.data.emailLabel).brandLabel()
                        TextField("", text: $model.email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focus, equals: .email)
                            .onSubmit { focus = .password }
                            .brandField()
                            .accessibilityLabel(model.data.emailLabel)
                            .accessibilityIdentifier("signIn.email")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.data.passwordLabel).brandLabel()
                        SecureField("", text: $model.password)
                            .textContentType(.password)
                            .submitLabel(.go)
                            .focused($focus, equals: .password)
                            .onSubmit(submit)
                            .brandField(isInvalid: model.errorMessage != nil)
                            .accessibilityLabel(model.data.passwordLabel)
                            .accessibilityIdentifier("signIn.password")
                        if let error = model.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(Color.phDanger)
                                .accessibilityIdentifier("signIn.error")
                        }
                    }

                    Button(action: submit) {
                        HStack(spacing: 8) {
                            if model.isSubmitting {
                                ProgressView().tint(Color.phOnFill)
                            }
                            Text(model.data.submitLabel)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!model.canSubmit)
                    .accessibilityIdentifier("signIn.submit")
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.phSurface)
            .navigationTitle(model.data.title)
        }
    }

    /// The message box: no connection after an attempt, else the
    /// session-ended notice until the user tries again.
    private var boxMessage: String? {
        if let connection = model.connectionMessage { return connection }
        if sessionEndedNotice && !model.hasAttempted { return model.data.sessionEndedMessage }
        return nil
    }

    private func submit() {
        focus = nil
        Task { await model.submit() }
    }
}

extension EnvironmentValues {
    /// True when the user was signed out because access ended, so the
    /// sign-in screen shows `session_ended_message`.
    @Entry var sessionEndedNotice: Bool = false
}

#Preview {
    SignInScreen(
        data: SignInScreenData(
            title: "Sign in", emailLabel: "Email", passwordLabel: "Password", submitLabel: "Sign in",
            cannotConnectMessage: "Can't connect.", sessionEndedMessage: "You've been signed out.",
            secondaryActions: []
        ),
        auth: PreviewAuthService()
    )
}

/// Preview-only stand-in; never signs in.
private struct PreviewAuthService: AuthService {
    func restoreSession() async -> AuthState { .signedOut(nil) }
    func signIn(email: String, password: String) async throws(SignInError) -> AuthUser {
        throw .rejected(code: "invalid_credentials", message: "That email and password don't match.")
    }
    func signOut() async {}
    func stateChanges() -> AsyncStream<AuthState> { AsyncStream { $0.finish() } }
    func renewAfterUnauthorized() async -> SessionRenewal { .notSignedIn }
    func endSession() async {}
}
