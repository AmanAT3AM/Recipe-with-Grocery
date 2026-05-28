import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var groceryVM: GroceryViewModel
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.discoverPath) {
                RecipeListView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .recipeDetail(let recipe):
                            RecipeDetailView(recipe: recipe)
                        case .settings:
                            SettingsView()
                        }
                    }
            }
            .tabItem { Label("Discover", systemImage: "sparkles") }
            .tag(AppTab.discover)

            NavigationStack(path: $router.favoritesPath) {
                FavoritesView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .recipeDetail(let recipe):
                            RecipeDetailView(recipe: recipe)
                        case .settings:
                            SettingsView()
                        }
                    }
            }
            .tabItem { Label("Favorites", systemImage: "heart.fill") }
            .tag(AppTab.favorites)

            NavigationStack(path: $router.groceryPath) {
                GroceryListView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .recipeDetail(let recipe):
                            RecipeDetailView(recipe: recipe)
                        case .settings:
                            SettingsView()
                        }
                    }
            }
            .tabItem {
                Label("Grocery", systemImage: "cart.fill")
            }
            .badge(groceryVM.totalCount > 0 ? groceryVM.totalCount : 0)
            .tag(AppTab.grocery)
        }
    }
}
