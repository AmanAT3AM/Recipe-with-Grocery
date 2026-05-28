import SwiftUI

@main
struct RecipeApp: App {
    @StateObject private var environment: AppEnvironment
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var recipeViewModel: RecipeViewModel
    @StateObject private var groceryViewModel: GroceryViewModel
    @StateObject private var router = AppRouter()

    init() {
        let environment = AppEnvironment()
        _environment = StateObject(wrappedValue: environment)
        _authViewModel = StateObject(
            wrappedValue: AuthViewModel(
                supabaseManager: environment.supabaseManager,
                sessionManager: environment.sessionManager
            )
        )
        _recipeViewModel = StateObject(
            wrappedValue: RecipeViewModel(
                apiService: environment.recipeAPIService,
                persistence: environment.persistenceController,
                networkMonitor: environment.networkMonitor
            )
        )
        _groceryViewModel = StateObject(
            wrappedValue: GroceryViewModel(persistence: environment.persistenceController)
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(environment)
                .environmentObject(environment.networkMonitor)
                .environmentObject(environment.sessionManager)
                .environmentObject(authViewModel)
                .environmentObject(recipeViewModel)
                .environmentObject(groceryViewModel)
                .environmentObject(router)
                .onOpenURL { url in
                    environment.sessionManager.handle(url: url)
                }
                .preferredColorScheme(.light)
        }
    }
}
