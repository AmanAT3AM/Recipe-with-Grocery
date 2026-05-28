import Auth
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header

                    VStack(spacing: 12) {
                        settingsRow(title: "Connection", value: networkMonitor.isConnected ? "Online" : "Offline", icon: "wifi")
                        settingsRow(title: "Session", value: sessionManager.displayName, icon: "person.circle")
                        settingsRow(title: "Recipes API", value: "DummyJSON", icon: "network")
                    }
                    .padding(16)
                    .background(Color.recipeSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )

                    Button(role: .destructive, action: signOut) {
                        Text("Sign out")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding(20)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Account")
                .font(.largeTitle.weight(.black))
            Text("Session status, environment details, and sign-out controls live here.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingsRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 36, height: 36)
                .foregroundStyle(.white)
                .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body.weight(.semibold))
            }
            Spacer()
        }
    }

    private func signOut() {
        Task {
            await authViewModel.signOut()
            dismiss()
        }
    }
}
