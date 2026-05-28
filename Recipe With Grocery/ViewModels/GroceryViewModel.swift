import Foundation
import Combine

@MainActor
final class GroceryViewModel: ObservableObject {
    @Published private(set) var groceryItems: [GroceryItem] = []
    @Published var showClearAlert: Bool = false

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        groceryItems = persistence.loadGlobalGroceryList()
    }

    func addIngredients(from recipe: Recipe) {
        guard let ingredients = recipe.extendedIngredients, !ingredients.isEmpty else { return }

        let newItems = ingredients.map { GroceryItem(from: $0, recipeTitle: recipe.title) }

        for newItem in newItems {
            if let existingIndex = groceryItems.firstIndex(where: { $0.normalizedKey == newItem.normalizedKey }) {
                groceryItems[existingIndex].amount += newItem.amount
                if !groceryItems[existingIndex].recipeTitle.localizedCaseInsensitiveContains(newItem.recipeTitle) {
                    groceryItems[existingIndex].recipeTitle += ", \(newItem.recipeTitle)"
                }
                groceryItems[existingIndex].isChecked = false
            } else {
                groceryItems.append(newItem)
            }
        }

        persist()
    }

    func toggleItem(_ item: GroceryItem) {
        guard let index = groceryItems.firstIndex(where: { $0.id == item.id }) else { return }
        groceryItems[index].isChecked.toggle()
        persist()
    }

    func removeItem(_ item: GroceryItem) {
        groceryItems.removeAll { $0.id == item.id }
        persist()
    }

    func removeCheckedItems() {
        groceryItems.removeAll { $0.isChecked }
        persist()
    }

    func clearAll() {
        groceryItems.removeAll()
        persist()
    }

    var groupedItems: [(GroceryCategory, [GroceryItem])] {
        let grouped = Dictionary(grouping: groceryItems, by: \.category)
        return GroceryCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var checkedCount: Int { groceryItems.filter(\.isChecked).count }
    var totalCount: Int { groceryItems.count }
    var allChecked: Bool { !groceryItems.isEmpty && groceryItems.allSatisfy(\.isChecked) }

    private func persist() {
        persistence.saveGlobalGroceryList(groceryItems)
    }
}
