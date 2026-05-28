import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var router: AppRouter
    @State private var didFinishSplash = false

    var body: some View {
        ZStack {
            AppBackgroundView()

            if !didFinishSplash || !sessionManager.hasResolvedInitialSession {
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else if !authViewModel.hasSeenOnboarding {
                OnboardingView(onContinue: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                        authViewModel.completeOnboarding()
                    }
                })
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if sessionManager.isAuthenticated {
                HomeView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                AuthFlowView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $router.isShowingSettings) {
            SettingsView()
                .presentationDetents([.large, .medium])
                .presentationCornerRadius(28)
        }
        .task {
            guard !didFinishSplash else { return }
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) {
                didFinishSplash = true
            }
        }
    }
}

private struct OnboardingView: View {
    let onContinue: () -> Void

    private let features: [(String, String)] = [
        ("fork.knife.circle.fill", "Discover recipes that match your mood, time, and pantry."),
        ("cart.badge.plus", "Build a grocery list from ingredients in one tap."),
        ("heart.circle.fill", "Save favorites and revisit them offline anytime.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 4)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recipe, grocery, and favorites in one polished flow.")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("A production-ready SwiftUI foundation with smooth navigation, local auth, and a modern visual language.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                ForEach(features, id: \.0) { item in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: item.0)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        Text(item.1)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .padding(14)
                    .background(Color.recipeSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                }

                Button(action: onContinue) {
                    Text("Get started")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(24)
        }
        .safeAreaPadding(.bottom, 8)
    }
}
