import Foundation

struct RecipeSearchResponse: Codable {
    let results: [Recipe]
    let offset: Int
    let number: Int
    let totalResults: Int
}

struct RandomRecipeResponse: Codable {
    let recipes: [Recipe]
}

struct Recipe: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let image: String?
    let imageType: String?
    let readyInMinutes: Int?
    let servings: Int?
    let summary: String?
    let instructions: String?
    let analyzedInstructions: [AnalyzedInstruction]?
    let extendedIngredients: [Ingredient]?
    let diets: [String]?
    let cuisines: [String]?
    let dishTypes: [String]?
    let spoonacularScore: Double?
    let healthScore: Double?
    let cheap: Bool?
    let vegan: Bool?
    let vegetarian: Bool?
    let glutenFree: Bool?
    let dairyFree: Bool?

    var imageURL: URL? {
        guard let image else { return nil }
        return URL(string: image)
    }

    var cleanSummary: String {
        guard let summary else { return "No description available." }
        return summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    var formattedScore: String {
        guard let score = spoonacularScore else { return "N/A" }
        return String(format: "%.0f", score)
    }
}

struct AnalyzedInstruction: Codable, Hashable {
    let name: String
    let steps: [InstructionStep]
}

struct InstructionStep: Codable, Hashable {
    let number: Int
    let step: String
    let ingredients: [StepIngredient]?
    let equipment: [StepEquipment]?
}

struct StepIngredient: Codable, Hashable {
    let id: Int
    let name: String
    let image: String?
}

struct StepEquipment: Codable, Hashable {
    let id: Int
    let name: String
    let image: String?
}
