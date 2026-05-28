import Foundation

struct Ingredient: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let originalName: String?
    let original: String?
    let amount: Double
    let unit: String
    let image: String?

    var displayText: String {
        original ?? originalName ?? "\(formattedAmount) \(unit) \(name)"
    }

    var formattedAmount: String {
        amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(amount))
            : String(format: "%.1f", amount)
    }

    var imageURL: URL? {
        guard let image else { return nil }
        return URL(string: "https://spoonacular.com/cdn/ingredients_100x100/\(image)")
    }
}
