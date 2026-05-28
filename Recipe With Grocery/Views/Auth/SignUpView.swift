import AuthenticationServices
import GoogleSignInSwift
import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    let onGoToLogin: () -> Void

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case email
        case password
        case confirmPassword
    }

    var body: some View {
        VStack(spacing: 18) {
            AuthCard {
                VStack(spacing: 14) {
                    AuthTextField(
                        title: "Display name",
                        text: $displayName,
                        textContentType: .name,
                        submitLabel: .next,
                        onSubmit: {
                            focusedField = .email
                        }
                    )
                    .focused($focusedField, equals: .name)

                    AuthTextField(
                        title: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        submitLabel: .next,
                        onSubmit: {
                            focusedField = .password
                        }
                    )
                    .focused($focusedField, equals: .email)

                    AuthSecureField(
                        title: "Password",
                        text: $password,
                        submitLabel: .next,
                        onSubmit: {
                            focusedField = .confirmPassword
                        }
                    )
                    .focused($focusedField, equals: .password)

                    AuthSecureField(
                        title: "Confirm password",
                        text: $confirmPassword,
                        submitLabel: .go,
                        onSubmit: {
                            Task { await signUp() }
                        }
                    )
                    .focused($focusedField, equals: .confirmPassword)

                    Text("Password must contain at least 6 characters. We will send a confirmation email before login.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        Task { await signUp() }
                    } label: {
                        AuthButtonLabel(title: authViewModel.isBusy ? "Creating account..." : "Create account")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(authViewModel.isBusy)

                    socialButtons

                    Button("Already have an account? Login") {
                        onGoToLogin()
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                    if let info = authViewModel.infoMessage {
                        Text(info)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.green)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .alert("Sign Up Error", isPresented: Binding(
            get: { authViewModel.errorMessage != nil },
            set: { if !$0 { authViewModel.clearError() } }
        )) {
            Button("OK", role: .cancel) { authViewModel.clearError() }
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
    }

    private func signUp() async {
        let didCreateAccount = await authViewModel.signUp(
            displayName: displayName,
            email: email,
            password: password,
            confirmPassword: confirmPassword
        )

        if didCreateAccount, !authViewModel.isAuthenticated {
            await MainActor.run {
                onGoToLogin()
            }
        }
    }

    private var socialButtons: some View {
        VStack(spacing: 12) {
            Divider().padding(.vertical, 4)

            GoogleSignInButton(
                scheme: .light,
                style: .wide,
                state: authViewModel.isBusy ? .disabled : .normal
            ) {
                Task {
                    await authViewModel.signInWithGoogle { url in
                        try await webAuthenticationSession.authenticate(
                            using: url,
                            callbackURLScheme: "recipewithgrocery"
                        )
                    }
                }
            }
            .frame(height: 50)

            SignInWithAppleButton(.signUp) { request in
                request.requestedScopes = [.email, .fullName]
            } onCompletion: { result in
                switch result {
                case .failure(let error):
                    authViewModel.errorMessage = error.localizedDescription
                case .success(let authorization):
                    guard
                        let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                        let identityTokenData = credential.identityToken,
                        let identityToken = String(data: identityTokenData, encoding: .utf8)
                    else {
                        authViewModel.errorMessage = AuthError.missingIdentityToken.localizedDescription
                        return
                    }

                    Task {
                        await authViewModel.signInWithApple(
                            idToken: identityToken,
                            fullName: credential.fullName?.formatted()
                        )
                    }
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .disabled(authViewModel.isBusy)
        }
    }
}
