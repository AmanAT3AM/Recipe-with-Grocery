import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int)
    case decodingFailed(Error)
    case noData
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL."
        case .requestFailed(let code):
            return "Request failed with status \(code)."
        case .decodingFailed(let err):
            return "Failed to decode response: \(err.localizedDescription)"
        case .noData:
            return "No data received from server."
        case .networkUnavailable:
            return "No internet connection."
        }
    }
}

protocol RecipeAPIServiceProtocol {
    func searchRecipes(query: String, page: Int) async throws -> RecipeSearchResponse
    func fetchRecipeDetail(id: Int) async throws -> Recipe
    func fetchRandomRecipes(tags: String) async throws -> [Recipe]
}

final class RecipeAPIService: RecipeAPIServiceProtocol {
    private let baseURL = URL(string: "https://dummyjson.com")!
    private let session: URLSession

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func searchRecipes(query: String, page: Int = 0) async throws -> RecipeSearchResponse {
        let limit = 10
        let skip = page * limit
        let response = try await fetch(
            path: "/recipes/search",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "skip", value: "\(skip)")
            ],
            as: DummyJSONRecipePageResponse.self
        )

        return RecipeSearchResponse(
            results: response.recipes.map(Self.mapRecipe(_:)),
            offset: response.skip,
            number: response.limit,
            totalResults: response.total
        )
    }

    func fetchRecipeDetail(id: Int) async throws -> Recipe {
        let response = try await fetch(
            path: "/recipes/\(id)",
            queryItems: nil,
            as: DummyJSONRecipeDetail.self
        )
        return Self.mapRecipe(response)
    }

    func fetchRandomRecipes(tags: String = "") async throws -> [Recipe] {
        let response = try await fetch(
            path: "/recipes",
            queryItems: [
                URLQueryItem(name: "limit", value: "0")
            ],
            as: DummyJSONRecipePageResponse.self
        )

        let recipes = response.recipes.map(Self.mapRecipe(_:))

        if tags.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Array(recipes.shuffled().prefix(12))
        }

        let desiredTags = Set(tags.lowercased().split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        let filtered = recipes.filter { recipe in
            let recipeTags = Set(recipe.dishTypes?.map { $0.lowercased() } ?? [])
                .union(Set(recipe.cuisines?.map { $0.lowercased() } ?? []))
            return !desiredTags.isDisjoint(with: recipeTags)
        }

        return Array((filtered.isEmpty ? recipes : filtered).shuffled().prefix(12))
    }

    private func fetch<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]?,
        as type: T.Type
    ) async throws -> T {
        let sanitizedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var components = URLComponents(
            url: baseURL.appendingPathComponent(sanitizedPath),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems
        guard let url = components?.url else { throw APIError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.noData }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    private static func mapRecipe(_ recipe: DummyJSONRecipeDetail) -> Recipe {
        let ingredients = recipe.ingredients.enumerated().map { index, ingredient in
            Ingredient(
                id: index + 1,
                name: ingredient,
                originalName: ingredient,
                original: ingredient,
                amount: 1,
                unit: "",
                image: nil
            )
        }

        let steps = recipe.instructions.enumerated().map { index, instruction in
            InstructionStep(
                number: index + 1,
                step: instruction,
                ingredients: nil,
                equipment: nil
            )
        }

        let analyzedInstructions = recipe.instructions.isEmpty ? nil : [
            AnalyzedInstruction(
                name: "Directions",
                steps: steps
            )
        ]

        let summary = recipe.instructions.isEmpty
            ? "A simple recipe from DummyJSON."
            : recipe.instructions.joined(separator: " ")

        return Recipe(
            id: recipe.id,
            title: recipe.name,
            image: recipe.image,
            imageType: "webp",
            readyInMinutes: recipe.prepTimeMinutes + recipe.cookTimeMinutes,
            servings: recipe.servings,
            summary: summary,
            instructions: recipe.instructions.joined(separator: "\n"),
            analyzedInstructions: analyzedInstructions,
            extendedIngredients: ingredients,
            diets: recipe.tags,
            cuisines: [recipe.cuisine].compactMap { $0.isEmpty ? nil : $0 },
            dishTypes: recipe.mealType,
            spoonacularScore: recipe.rating * 20,
            healthScore: recipe.rating * 20,
            cheap: nil,
            vegan: recipe.tags.contains { $0.lowercased() == "vegan" },
            vegetarian: recipe.tags.contains { $0.lowercased() == "vegetarian" },
            glutenFree: recipe.tags.contains { $0.lowercased() == "gluten free" || $0.lowercased() == "gluten-free" },
            dairyFree: recipe.tags.contains { $0.lowercased() == "dairy free" || $0.lowercased() == "dairy-free" }
        )
    }
}

private struct DummyJSONRecipePageResponse: Decodable {
    let recipes: [DummyJSONRecipeDetail]
    let total: Int
    let skip: Int
    let limit: Int
}

private struct DummyJSONRecipeDetail: Decodable {
    let id: Int
    let name: String
    let ingredients: [String]
    let instructions: [String]
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let servings: Int?
    let difficulty: String?
    let cuisine: String
    let caloriesPerServing: Double
    let tags: [String]
    let image: String?
    let rating: Double
    let reviewCount: Int?
    let mealType: [String]
}
