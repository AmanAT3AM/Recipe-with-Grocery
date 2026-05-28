import SwiftUI

struct AppBackgroundView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.recipeBackground,
                    Color(red: 0.98, green: 0.99, blue: 1.00),
                    Color(red: 0.94, green: 0.98, blue: 0.97)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.recipeAccent.opacity(0.18), .clear],
                center: animate ? .topTrailing : .bottomLeading,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.recipeMint.opacity(0.12), .clear],
                center: animate ? .bottomLeading : .topTrailing,
                startRadius: 24,
                endRadius: 360
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.recipeAccent.opacity(0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 72)
                .offset(x: animate ? 140 : -150, y: animate ? -240 : -280)
                .animation(.easeInOut(duration: 11).repeatForever(autoreverses: true), value: animate)

            Circle()
                .fill(Color.recipeMint.opacity(0.08))
                .frame(width: 240, height: 240)
                .blur(radius: 64)
                .offset(x: animate ? -120 : 130, y: animate ? 260 : 220)
                .animation(.easeInOut(duration: 13).repeatForever(autoreverses: true), value: animate)

            RoundedRectangle(cornerRadius: 180, style: .continuous)
                .fill(Color.white.opacity(0.48))
                .frame(width: 260, height: 180)
                .blur(radius: 40)
                .offset(x: animate ? -170 : -120, y: -90)
                .rotationEffect(.degrees(18))
                .animation(.easeInOut(duration: 15).repeatForever(autoreverses: true), value: animate)
        }
        .onAppear { animate = true }
    }
}

struct AppHeroBanner: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(colors: [Color.accentColor, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.black.opacity(0.04), lineWidth: 1)
        }
    }
}
