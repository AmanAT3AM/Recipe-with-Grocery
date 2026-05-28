import Foundation

struct GroceryItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let ingredientName: String
    var originalText: String
    var amount: Double
    var unit: String
    var recipeTitle: String
    var isChecked: Bool = false
    var category: GroceryCategory

    init(from ingredient: Ingredient, recipeTitle: String) {
        self.ingredientName = ingredient.name
        self.originalText = ingredient.displayText
        self.amount = ingredient.amount
        self.unit = ingredient.unit
        self.recipeTitle = recipeTitle
        self.category = GroceryCategory.categorize(name: ingredient.name)
    }

    var normalizedKey: String {
        ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

enum GroceryCategory: String, Codable, CaseIterable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat & Seafood"
    case bakery = "Bakery"
    case pantry = "Pantry"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case other = "Other"

    var icon: String {
        switch self {
        case .produce: return "leaf"
        case .dairy: return "cup.and.saucer"
        case .meat: return "fork.knife"
        case .bakery: return "birthday.cake"
        case .pantry: return "cabinet"
        case .frozen: return "snowflake"
        case .beverages: return "waterbottle"
        case .other: return "bag"
        }
    }

    static func categorize(name: String) -> GroceryCategory {
        let lower = name.lowercased()
        let produceKeywords = ["lettuce", "spinach", "tomato", "onion", "garlic", "pepper", "carrot", "broccoli", "apple", "banana", "lemon", "lime", "avocado", "cucumber", "zucchini", "mushroom", "herb", "basil", "cilantro", "parsley", "thyme", "rosemary"]
        let dairyKeywords = ["milk", "cheese", "butter", "cream", "yogurt", "egg", "parmesan", "cheddar", "mozzarella"]
        let meatKeywords = ["chicken", "beef", "pork", "lamb", "salmon", "shrimp", "tuna", "turkey", "bacon", "sausage", "fish"]
        let bakeryKeywords = ["bread", "flour", "yeast", "baguette", "roll", "bun", "tortilla", "pita"]
        let pantryKeywords = ["oil", "vinegar", "salt", "pepper", "sugar", "honey", "sauce", "paste", "can", "stock", "broth", "spice", "cumin", "paprika", "cinnamon", "rice", "pasta", "noodle"]
        let frozenKeywords = ["frozen", "ice", "pea"]
        let beveragesKeywords = ["water", "juice", "wine", "beer", "broth", "coffee", "tea", "milk", "soda"]

        if produceKeywords.contains(where: { lower.contains($0) }) { return .produce }
        if dairyKeywords.contains(where: { lower.contains($0) }) { return .dairy }
        if meatKeywords.contains(where: { lower.contains($0) }) { return .meat }
        if bakeryKeywords.contains(where: { lower.contains($0) }) { return .bakery }
        if pantryKeywords.contains(where: { lower.contains($0) }) { return .pantry }
        if frozenKeywords.contains(where: { lower.contains($0) }) { return .frozen }
        if beveragesKeywords.contains(where: { lower.contains($0) }) { return .beverages }
        return .other
    }
}
