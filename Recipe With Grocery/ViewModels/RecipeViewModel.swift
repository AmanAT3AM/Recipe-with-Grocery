import Foundation
import Combine

@MainActor
final class RecipeViewModel: ObservableObject {
    @Published private(set) var recipes: [Recipe] = []
    @Published private(set) var searchResults: [Recipe] = []
    @Published private(set) var selectedRecipe: Recipe?
    @Published private(set) var favorites: [FavoriteRecipeEntity] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isLoadingMore: Bool = false
    @Published var errorMessage: String?
    @Published var searchQuery: String = ""

    private var currentPage = 0
    private var canLoadMore = true
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private let apiService: RecipeAPIServiceProtocol
    private let persistence: PersistenceController
    private let networkMonitor: NetworkMonitor

    init(
        apiService: RecipeAPIServiceProtocol = RecipeAPIService(),
        persistence: PersistenceController = .shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.apiService = apiService
        self.persistence = persistence
        self.networkMonitor = networkMonitor
        setupSearchDebounce()
        loadFavorites()
    }

    var displayedRecipes: [Recipe] {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? recipes : searchResults
    }

    var hasResults: Bool {
        !displayedRecipes.isEmpty
    }

    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(450), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self else { return }
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                self.searchTask?.cancel()
                if trimmed.isEmpty {
                    self.searchResults = []
                } else {
                    self.searchTask = Task { await self.search(query: trimmed) }
                }
            }
            .store(in: &cancellables)
    }

    func loadRecipes() async {
        guard !isLoading else { return }
        guard networkMonitor.isConnected else {
            errorMessage = APIError.networkUnavailable.localizedDescription
            return
        }
        isLoading = true
        currentPage = 0
        canLoadMore = true
        defer { isLoading = false }

        do {
            recipes = try await apiService.fetchRandomRecipes(tags: "")
            if recipes.isEmpty {
                errorMessage = "No recipes were returned."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func search(query: String) async {
        guard !query.isEmpty else { return }
        guard networkMonitor.isConnected else {
            errorMessage = APIError.networkUnavailable.localizedDescription
            return
        }
        guard !Task.isCancelled else { return }
        isLoading = true
        currentPage = 0
        canLoadMore = true
        defer { isLoading = false }

        do {
            let response = try await apiService.searchRecipes(query: query, page: 0)
            guard !Task.isCancelled else { return }
            searchResults = response.results
            canLoadMore = response.results.count == response.number
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }

    func loadMoreIfNeeded(currentItem item: Recipe) async {
        guard canLoadMore, !isLoadingMore else { return }
        guard let last = searchResults.last, last.id == item.id else { return }

        isLoadingMore = true
        currentPage += 1
        defer { isLoadingMore = false }

        do {
            let response = try await apiService.searchRecipes(query: searchQuery, page: currentPage)
            if response.results.isEmpty {
                canLoadMore = false
            } else {
                searchResults.append(contentsOf: response.results)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectRecipe(_ recipe: Recipe) async {
        isLoading = true
        defer { isLoading = false }

        do {
            selectedRecipe = try await apiService.fetchRecipeDetail(id: recipe.id)
        } catch {
            selectedRecipe = recipe
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleFavorite(_ recipe: Recipe) {
        if persistence.isFavorite(id: recipe.id) {
            persistence.removeFavorite(id: recipe.id)
        } else {
            persistence.saveFavorite(recipe)
        }
        loadFavorites()
    }

    func isFavorite(_ recipe: Recipe) -> Bool {
        persistence.isFavorite(id: recipe.id)
    }

    func loadFavorites() {
        favorites = persistence.fetchAllFavorites()
    }

    func clearError() {
        errorMessage = nil
    }
}
