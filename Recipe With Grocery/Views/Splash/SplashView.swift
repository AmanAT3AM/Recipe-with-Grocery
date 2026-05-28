import SwiftUI

struct SplashView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.85), Color.accentColor.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 120
                        )
                    )
                    .frame(width: 220, height: 220)
                    .scaleEffect(pulse ? 1.05 : 0.94)
                    .opacity(pulse ? 1 : 0.7)

                Image(systemName: "fork.knife")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(28)
                    .background(Color.recipeSurface, in: Circle())
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
            }

            VStack(spacing: 8) {
                Text("Recipe With Grocery")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                Text("Cook beautifully, shop intelligently.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
    }
}
