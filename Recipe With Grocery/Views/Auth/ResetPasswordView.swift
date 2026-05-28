import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email: String

    init(initialEmail: String = "") {
        _email = State(initialValue: initialEmail)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                AuthCard {
                    VStack(spacing: 14) {
                        AuthTextField(
                            title: "Email",
                            text: $email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )

                        Button {
                            Task { await sendReset() }
                        } label: {
                            AuthButtonLabel(title: authViewModel.isBusy ? "Sending..." : "Send reset link")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(authViewModel.isBusy)

                        if let info = authViewModel.infoMessage {
                            Text(info)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.green)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Reset Password")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .alert("Reset Error", isPresented: Binding(
            get: { authViewModel.errorMessage != nil },
            set: { if !$0 { authViewModel.clearError() } }
        )) {
            Button("OK", role: .cancel) { authViewModel.clearError() }
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
    }

    private func sendReset() async {
        await authViewModel.requestPasswordReset(email: email)
    }
}
