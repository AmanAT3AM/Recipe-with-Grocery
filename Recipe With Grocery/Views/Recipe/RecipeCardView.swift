import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe
    @EnvironmentObject private var recipeVM: RecipeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncCachedImage(url: recipe.imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.recipeBackground)
                        .overlay {
                            Image(systemName: "fork.knife")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(height: 138)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    recipeVM.toggleFavorite(recipe)
                } label: {
                    Image(systemName: recipeVM.isFavorite(recipe) ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(recipeVM.isFavorite(recipe) ? .red : .primary)
                        .padding(10)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                HStack(spacing: 10) {
                    if let mins = recipe.readyInMinutes {
                        Label("\(mins)m", systemImage: "clock")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    if let score = recipe.spoonacularScore {
                        Label(String(format: "%.0f", score), systemImage: "star.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.black.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }
}
