import SwiftUI

struct AuthFlowView: View {
    @State private var mode: AuthMode = .login

    enum AuthMode: String, CaseIterable {
        case login = "Login"
        case signUp = "Sign Up"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                modePicker

                Group {
                    switch mode {
                    case .login:
                        LoginView(onGoToSignUp: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                                mode = .signUp
                            }
                        })
                    case .signUp:
                        SignUpView(onGoToLogin: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                                mode = .login
                            }
                        })
                    }
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.recipeAccent.gradient, in: Circle())

                Text("Food Buddy")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.1)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(mode == .login ? "Cook with feeling." : "Start a lighter kitchen.")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(mode == .login
                     ? "Sign in to keep your favorites, grocery list, and recipes in one soft, bright space."
                     : "Create your account and save the meals you love with a clean, airy interface.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                pill(text: "Fresh layout", icon: "sun.max.fill")
                pill(text: "Fast save", icon: "heart.fill")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.96),
                    Color.white.opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.black.opacity(0.05), lineWidth: 1)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 10) {
            ForEach(AuthMode.allCases, id: \.self) { item in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        mode = item
                    }
                } label: {
                    Text(item.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(mode == item ? .white : .primary)
                        .background {
                            if mode == item {
                                Capsule().fill(Color.recipeAccent.gradient)
                            } else {
                                Capsule().fill(Color.white)
                            }
                        }
                        .overlay {
                            Capsule().strokeBorder(.black.opacity(0.06), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func pill(text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white, in: Capsule())
            .overlay {
                Capsule().strokeBorder(.black.opacity(0.06), lineWidth: 1)
            }
    }
}
