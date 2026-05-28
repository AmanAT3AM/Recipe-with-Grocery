import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var router: AppRouter
    @State private var showSignOutConfirmation = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MainTabView()

            Button {
                showSignOutConfirmation = true
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay {
                        Circle().strokeBorder(.black.opacity(0.06), lineWidth: 1)
                    }
            }
            .padding(.top, 12)
            .padding(.trailing, 16)
        }
        .confirmationDialog(
            "Sign out?",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await authViewModel.signOut()
                    router.popToRoot(.discover)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will return to the login screen.")
        }
    }
}
