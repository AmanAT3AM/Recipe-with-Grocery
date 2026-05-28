import Foundation
import Combine

@MainActor
final class AppEnvironment: ObservableObject {
    let recipeAPIService: RecipeAPIServiceProtocol
    let persistenceController: PersistenceController
    let networkMonitor: NetworkMonitor
    let supabaseManager: SupabaseManager
    let sessionManager: SessionManager

    init(
        recipeAPIService: RecipeAPIServiceProtocol = RecipeAPIService(),
        persistenceController: PersistenceController = .shared,
        networkMonitor: NetworkMonitor = .shared,
        supabaseManager: SupabaseManager = .shared
    ) {
        self.recipeAPIService = recipeAPIService
        self.persistenceController = persistenceController
        self.networkMonitor = networkMonitor
        self.supabaseManager = supabaseManager
        self.sessionManager = SessionManager(supabaseManager: supabaseManager)
    }
}
