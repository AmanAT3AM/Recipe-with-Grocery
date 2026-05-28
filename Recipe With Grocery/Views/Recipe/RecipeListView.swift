import SwiftUI

struct RecipeListView: View {
    @EnvironmentObject private var recipeVM: RecipeViewModel
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                header
                SearchBar(text: $recipeVM.searchQuery, placeholder: "Search recipes...")
                    .padding(.horizontal, 20)

                if recipeVM.isLoading && recipeVM.displayedRecipes.isEmpty {
                    loadingGrid
                } else if recipeVM.displayedRecipes.isEmpty && !recipeVM.searchQuery.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No results found",
                        message: "Try a different ingredient, meal type, or cuisine.",
                        actionTitle: "Clear search",
                        action: { recipeVM.searchQuery = "" }
                    )
                    .padding(.top, 30)
                } else {
                    recipeGrid
                }
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Recipe With Grocery")
                    .font(.headline.weight(.bold))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.isShowingSettings = true
                } label: {
                    Image(systemName: "person.crop.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await recipeVM.loadRecipes() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .alert("Error", isPresented: .init(
            get: { recipeVM.errorMessage != nil },
            set: { if !$0 { recipeVM.clearError() } }
        )) {
            Button("OK") { recipeVM.clearError() }
        } message: {
            Text(recipeVM.errorMessage ?? "")
        }
        .task {
            if recipeVM.recipes.isEmpty {
                await recipeVM.loadRecipes()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppHeroBanner(
                title: "Cook something new tonight",
                subtitle: "Browse fake but realistic recipes with favorites and grocery sync.",
                symbol: "sparkles"
            )
            .padding(.horizontal, 20)

            HStack(spacing: 10) {
                statChip(title: "Recipes", value: "\(recipeVM.displayedRecipes.count)")
                statChip(title: "Saved", value: "\(recipeVM.favorites.count)")
            }
            .padding(.horizontal, 20)
        }
    }

    private func statChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.recipeSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var recipeGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14)], spacing: 14) {
            ForEach(recipeVM.displayedRecipes) { recipe in
                NavigationLink(value: AppRoute.recipeDetail(recipe)) {
                    RecipeCardView(recipe: recipe)
                }
                .buttonStyle(.plain)
                .onAppear {
                    Task { await recipeVM.loadMoreIfNeeded(currentItem: recipe) }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var loadingGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14)], spacing: 14) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.recipeSurfaceElevated)
                    .frame(height: 230)
                    .shimmer()
            }
        }
        .padding(.horizontal, 20)
    }
}
