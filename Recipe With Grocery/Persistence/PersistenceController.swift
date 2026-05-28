import CoreData
import Foundation

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var context: NSManagedObjectContext {
        container.viewContext
    }

    private init(inMemory: Bool = false) {
        let model = Self.makeManagedObjectModel()
        container = NSPersistentContainer(name: "RecipeModel", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "FavoriteRecipeEntity"
        entity.managedObjectClassName = NSStringFromClass(FavoriteRecipeEntity.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .integer64AttributeType
        idAttribute.isOptional = false

        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = true

        let imageURLAttribute = NSAttributeDescription()
        imageURLAttribute.name = "imageURL"
        imageURLAttribute.attributeType = .stringAttributeType
        imageURLAttribute.isOptional = true

        let savedAtAttribute = NSAttributeDescription()
        savedAtAttribute.name = "savedAt"
        savedAtAttribute.attributeType = .dateAttributeType
        savedAtAttribute.isOptional = false

        entity.properties = [idAttribute, titleAttribute, imageURLAttribute, savedAtAttribute]
        model.entities = [entity]
        return model
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            assertionFailure("Core Data save error: \(error.localizedDescription)")
        }
    }

    func saveFavorite(_ recipe: Recipe) {
        let existing = fetchFavorite(id: recipe.id)
        let entity = existing ?? FavoriteRecipeEntity(context: context)
        entity.id = Int64(recipe.id)
        entity.title = recipe.title
        entity.imageURL = recipe.image
        entity.savedAt = Date()
        save()
    }

    func removeFavorite(id: Int) {
        guard let entity = fetchFavorite(id: id) else { return }
        context.delete(entity)
        save()
    }

    func isFavorite(id: Int) -> Bool {
        fetchFavorite(id: id) != nil
    }

    func fetchAllFavorites() -> [FavoriteRecipeEntity] {
        let request: NSFetchRequest<FavoriteRecipeEntity> = FavoriteRecipeEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "savedAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    private func fetchFavorite(id: Int) -> FavoriteRecipeEntity? {
        let request: NSFetchRequest<FavoriteRecipeEntity> = FavoriteRecipeEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %d", id)
        return try? context.fetch(request).first
    }

    func saveGroceryList(_ items: [GroceryItem], forRecipeID id: Int) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: "grocery_\(id)")
    }

    func loadGroceryList(forRecipeID id: Int) -> [GroceryItem] {
        guard let data = UserDefaults.standard.data(forKey: "grocery_\(id)"),
              let items = try? JSONDecoder().decode([GroceryItem].self, from: data)
        else { return [] }
        return items
    }

    func saveGlobalGroceryList(_ items: [GroceryItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: "global_grocery_list")
    }

    func loadGlobalGroceryList() -> [GroceryItem] {
        guard let data = UserDefaults.standard.data(forKey: "global_grocery_list"),
              let items = try? JSONDecoder().decode([GroceryItem].self, from: data)
        else { return [] }
        return items
    }
}

@objc(FavoriteRecipeEntity)
final class FavoriteRecipeEntity: NSManagedObject {
    @NSManaged var id: Int64
    @NSManaged var title: String?
    @NSManaged var imageURL: String?
    @NSManaged var savedAt: Date
}

extension FavoriteRecipeEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FavoriteRecipeEntity> {
        NSFetchRequest<FavoriteRecipeEntity>(entityName: "FavoriteRecipeEntity")
    }
}
