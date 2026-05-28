import AuthenticationServices
import GoogleSignInSwift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    let onGoToSignUp: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var showResetPassword = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        VStack(spacing: 18) {
            AuthCard {
                VStack(spacing: 14) {
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
                        submitLabel: .go,
                        onSubmit: {
                            Task { await signIn() }
                        }
                    )
                    .focused($focusedField, equals: .password)

                    Button {
                        Task { await signIn() }
                    } label: {
                        AuthButtonLabel(title: authViewModel.isBusy ? "Logging in..." : "Login")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(authViewModel.isBusy)

                    socialButtons

                    Button("Forgot password?") {
                        showResetPassword = true
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                    Button("Create a new account") {
                        onGoToSignUp()
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
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordView(initialEmail: email)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(28)
        }
        .alert("Login Error", isPresented: Binding(
            get: { authViewModel.errorMessage != nil },
            set: { if !$0 { authViewModel.clearError() } }
        )) {
            Button("OK", role: .cancel) { authViewModel.clearError() }
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
    }

    private func signIn() async {
        await authViewModel.signIn(email: email, password: password)
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

            SignInWithAppleButton(.signIn) { request in
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
