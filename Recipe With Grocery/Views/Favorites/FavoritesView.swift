import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var recipeVM: RecipeViewModel
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                header

                if recipeVM.favorites.isEmpty {
                    EmptyStateView(
                        icon: "heart.slash",
                        title: "No favorites yet",
                        message: "Tap the heart on any recipe to save it here."
                    )
                    .padding(.top, 20)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14)], spacing: 14) {
                        ForEach(recipeVM.favorites, id: \.id) { entity in
                            NavigationLink(value: AppRoute.recipeDetail(stubRecipe(from: entity))) {
                                FavoriteCardView(entity: entity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Favorites")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.isShowingSettings = true
                } label: {
                    Image(systemName: "person.crop.circle")
                }
            }
        }
        .task {
            recipeVM.loadFavorites()
        }
    }

    private var header: some View {
        AppHeroBanner(
            title: "Your saved recipes",
            subtitle: "Tap into the meals you keep coming back to.",
            symbol: "heart.circle.fill"
        )
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private func stubRecipe(from entity: FavoriteRecipeEntity) -> Recipe {
        Recipe(
            id: Int(entity.id),
            title: entity.title ?? "Favorite Recipe",
            image: entity.imageURL,
            imageType: nil,
            readyInMinutes: nil,
            servings: nil,
            summary: nil,
            instructions: nil,
            analyzedInstructions: nil,
            extendedIngredients: nil,
            diets: nil,
            cuisines: nil,
            dishTypes: nil,
            spoonacularScore: nil,
            healthScore: nil,
            cheap: nil,
            vegan: nil,
            vegetarian: nil,
            glutenFree: nil,
            dairyFree: nil
        )
    }
}

struct FavoriteCardView: View {
    let entity: FavoriteRecipeEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncCachedImage(url: entity.imageURL.flatMap(URL.init)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.recipeBackground)
                    .overlay {
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(height: 135)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(entity.title ?? "")
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.black.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 14, y: 8)
    }
}
