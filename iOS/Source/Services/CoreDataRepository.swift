import Foundation
import CoreData
import Combine

final class CoreDataRepository: ObservableObject, RepositoryProtocol {
    @Published private(set) var recipes: [Recipe] = []

    private let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = CoreDataRepository.makeModel()
        container = NSPersistentContainer(name: "Forkfolio", managedObjectModel: model)
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { _, error in
            if let error = error { print("CoreData load error: \(error)") }
        }
        refresh()
    }

    // MARK: - RepositoryProtocol

    func add(_ recipe: Recipe) {
        let ctx = container.viewContext
        let cdRecipe = NSEntityDescription.insertNewObject(forEntityName: "CDRecipe", into: ctx)
        CoreDataRepository.write(recipe: recipe, to: cdRecipe, in: ctx)
        save()
        refresh()
    }

    func update(_ recipe: Recipe) {
        let ctx = container.viewContext
        guard let cd = fetchCDRecipe(by: recipe.id, context: ctx) else { return }
        // Remove children first
        if let ings = cd.value(forKey: "ingredients") as? Set<NSManagedObject> {
            for i in ings { ctx.delete(i) }
        }
        if let steps = cd.value(forKey: "steps") as? Set<NSManagedObject> {
            for s in steps { ctx.delete(s) }
        }
        if let creator = cd.value(forKey: "creator") as? NSManagedObject { ctx.delete(creator) }
        CoreDataRepository.write(recipe: recipe, to: cd, in: ctx)
        save()
        refresh()
    }

    func delete(_ recipe: Recipe) {
        let ctx = container.viewContext
        if let cd = fetchCDRecipe(by: recipe.id, context: ctx) { ctx.delete(cd); save(); refresh() }
    }

    func search(query: String, tags: [String], creatorNames: [String], favoritesOnly: Bool) -> [Recipe] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return recipes.filter { r in
            let matchesQuery = q.isEmpty || r.title.lowercased().contains(q) || r.notes?.lowercased().contains(q) == true || r.ingredients.contains { $0.text.lowercased().contains(q) } || r.steps.contains { $0.text.lowercased().contains(q) } || (r.creator?.name.lowercased().contains(q) ?? false)
            let matchesTags = tags.isEmpty || !Set(tags.map { $0.lowercased() }).isDisjoint(with: r.tags.map { $0.lowercased() })
            let matchesCreator = creatorNames.isEmpty || (r.creator.map { creatorNames.map { $0.lowercased() }.contains($0.name.lowercased()) } ?? false)
            let matchesFav = !favoritesOnly || r.favorite
            return matchesQuery && matchesTags && matchesCreator && matchesFav
        }
    }

    // MARK: - Core Data helpers

    private func refresh() {
        let ctx = container.viewContext
        let req = NSFetchRequest<NSManagedObject>(entityName: "CDRecipe")
        req.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        do {
            let items = try ctx.fetch(req)
            self.recipes = items.compactMap { CoreDataRepository.read(recipe: $0) }
        } catch {
            print("Fetch error: \(error)")
            self.recipes = []
        }
    }

    private func fetchCDRecipe(by id: UUID, context: NSManagedObjectContext) -> NSManagedObject? {
        let req = NSFetchRequest<NSManagedObject>(entityName: "CDRecipe")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return try? context.fetch(req).first
    }

    private func save() {
        let ctx = container.viewContext
        if ctx.hasChanges {
            do { try ctx.save() } catch { print("Save error: \(error)") }
        }
    }

    // MARK: - Mapping

    private static func write(recipe: Recipe, to obj: NSManagedObject, in ctx: NSManagedObjectContext) {
        obj.setValue(recipe.id, forKey: "id")
        obj.setValue(recipe.title, forKey: "title")
        obj.setValue(recipe.sourceURL?.absoluteString, forKey: "sourceURL")
        obj.setValue(recipe.imageData, forKey: "imageData")
        obj.setValue(recipe.tags, forKey: "tags")
        obj.setValue(recipe.favorite, forKey: "favorite")
        obj.setValue(recipe.rating as NSNumber?, forKey: "rating")
        obj.setValue(recipe.prepMinutes as NSNumber?, forKey: "prepMinutes")
        obj.setValue(recipe.cookMinutes as NSNumber?, forKey: "cookMinutes")
        obj.setValue(recipe.servings as NSNumber?, forKey: "servings")
        obj.setValue(recipe.notes, forKey: "notes")
        obj.setValue(recipe.dateAdded, forKey: "dateAdded")

        if let creator = recipe.creator {
            let cdCreator = NSEntityDescription.insertNewObject(forEntityName: "CDCreator", into: ctx)
            cdCreator.setValue(creator.id, forKey: "id")
            cdCreator.setValue(creator.name, forKey: "name")
            cdCreator.setValue(creator.platform, forKey: "platform")
            cdCreator.setValue(creator.profileURL?.absoluteString, forKey: "profileURL")
            obj.setValue(cdCreator, forKey: "creator")
        }

        let cdIngs = recipe.ingredients.map { ing -> NSManagedObject in
            let o = NSEntityDescription.insertNewObject(forEntityName: "CDIngredient", into: ctx)
            o.setValue(ing.id, forKey: "id")
            o.setValue(ing.text, forKey: "text")
            o.setValue(ing.quantity, forKey: "quantity")
            o.setValue(ing.unit, forKey: "unit")
            return o
        }
        obj.setValue(NSSet(array: cdIngs), forKey: "ingredients")

        let cdSteps = recipe.steps.map { step -> NSManagedObject in
            let o = NSEntityDescription.insertNewObject(forEntityName: "CDStep", into: ctx)
            o.setValue(step.id, forKey: "id")
            o.setValue(step.order, forKey: "order")
            o.setValue(step.text, forKey: "text")
            return o
        }
        obj.setValue(NSSet(array: cdSteps), forKey: "steps")
    }

    private static func read(recipe obj: NSManagedObject) -> Recipe? {
        guard let id = obj.value(forKey: "id") as? UUID,
              let title = obj.value(forKey: "title") as? String,
              let dateAdded = obj.value(forKey: "dateAdded") as? Date
        else { return nil }
        let sourceURLStr = obj.value(forKey: "sourceURL") as? String
        let sourceURL = sourceURLStr.flatMap(URL.init(string:))
        let imageData = obj.value(forKey: "imageData") as? Data
        let tags = obj.value(forKey: "tags") as? [String] ?? []
        let favorite = obj.value(forKey: "favorite") as? Bool ?? false
        let rating = obj.value(forKey: "rating") as? Int
        let prep = obj.value(forKey: "prepMinutes") as? Int
        let cook = obj.value(forKey: "cookMinutes") as? Int
        let servings = obj.value(forKey: "servings") as? Int
        let notes = obj.value(forKey: "notes") as? String

        var creator: Creator? = nil
        if let c = obj.value(forKey: "creator") as? NSManagedObject {
            let cid = (c.value(forKey: "id") as? UUID) ?? UUID()
            let name = (c.value(forKey: "name") as? String) ?? ""
            let platform = (c.value(forKey: "platform") as? String) ?? "web"
            let profileURL = (c.value(forKey: "profileURL") as? String).flatMap(URL.init(string:))
            creator = Creator(id: cid, name: name, platform: platform, profileURL: profileURL)
        }

        var ingredients: [Ingredient] = []
        if let set = obj.value(forKey: "ingredients") as? Set<NSManagedObject> {
            ingredients = set.compactMap { o in
                guard let id = o.value(forKey: "id") as? UUID,
                      let text = o.value(forKey: "text") as? String else { return nil }
                let qty = o.value(forKey: "quantity") as? String
                let unit = o.value(forKey: "unit") as? String
                return Ingredient(id: id, text: text, quantity: qty, unit: unit)
            }.sorted { $0.text < $1.text }
        }

        var steps: [Step] = []
        if let set = obj.value(forKey: "steps") as? Set<NSManagedObject> {
            steps = set.compactMap { o in
                guard let id = o.value(forKey: "id") as? UUID,
                      let order = o.value(forKey: "order") as? Int,
                      let text = o.value(forKey: "text") as? String else { return nil }
                return Step(id: id, order: order, text: text)
            }.sorted { $0.order < $1.order }
        }

        return Recipe(id: id, title: title, sourceURL: sourceURL, creator: creator, imageData: imageData, tags: tags, favorite: favorite, rating: rating, prepMinutes: prep, cookMinutes: cook, servings: servings, notes: notes, ingredients: ingredients, steps: steps, dateAdded: dateAdded)
    }

    // MARK: - Managed Object Model (programmatic)

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Entities
        let recipe = NSEntityDescription(); recipe.name = "CDRecipe"; recipe.managedObjectClassName = "NSManagedObject"
        let ingredient = NSEntityDescription(); ingredient.name = "CDIngredient"; ingredient.managedObjectClassName = "NSManagedObject"
        let step = NSEntityDescription(); step.name = "CDStep"; step.managedObjectClassName = "NSManagedObject"
        let creator = NSEntityDescription(); creator.name = "CDCreator"; creator.managedObjectClassName = "NSManagedObject"

        // CDRecipe attributes
        recipe.properties = [
            makeAttribute(name: "id", type: .UUIDAttributeType, isOptional: false),
            makeAttribute(name: "title", type: .stringAttributeType),
            makeAttribute(name: "sourceURL", type: .stringAttributeType, isOptional: true),
            makeAttribute(name: "imageData", type: .binaryDataAttributeType, isOptional: true),
            makeAttribute(name: "tags", type: .transformableAttributeType, isOptional: true),
            makeAttribute(name: "favorite", type: .booleanAttributeType),
            makeAttribute(name: "rating", type: .integer32AttributeType, isOptional: true),
            makeAttribute(name: "prepMinutes", type: .integer32AttributeType, isOptional: true),
            makeAttribute(name: "cookMinutes", type: .integer32AttributeType, isOptional: true),
            makeAttribute(name: "servings", type: .integer32AttributeType, isOptional: true),
            makeAttribute(name: "notes", type: .stringAttributeType, isOptional: true),
            makeAttribute(name: "dateAdded", type: .dateAttributeType)
        ]

        // CDIngredient attributes
        ingredient.properties = [
            makeAttribute(name: "id", type: .UUIDAttributeType, isOptional: false),
            makeAttribute(name: "text", type: .stringAttributeType),
            makeAttribute(name: "quantity", type: .stringAttributeType, isOptional: true),
            makeAttribute(name: "unit", type: .stringAttributeType, isOptional: true)
        ]

        // CDStep attributes
        step.properties = [
            makeAttribute(name: "id", type: .UUIDAttributeType, isOptional: false),
            makeAttribute(name: "order", type: .integer32AttributeType),
            makeAttribute(name: "text", type: .stringAttributeType)
        ]

        // CDCreator attributes
        creator.properties = [
            makeAttribute(name: "id", type: .UUIDAttributeType, isOptional: false),
            makeAttribute(name: "name", type: .stringAttributeType),
            makeAttribute(name: "platform", type: .stringAttributeType),
            makeAttribute(name: "profileURL", type: .stringAttributeType, isOptional: true)
        ]

        // Relationships
        let relIngredients = makeToMany(name: "ingredients", destination: ingredient, inverseName: nil)
        let relSteps = makeToMany(name: "steps", destination: step, inverseName: nil)
        let relCreator = makeToOne(name: "creator", destination: creator, inverseName: nil, optional: true)
        recipe.properties.append(contentsOf: [relIngredients, relSteps, relCreator])

        model.entities = [recipe, ingredient, step, creator]
        return model
    }

    private static func makeAttribute(name: String, type: NSAttributeType, isOptional: Bool = false) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = type
        a.isOptional = isOptional
        if type == .transformableAttributeType {
            a.valueTransformerName = NSValueTransformerName.secureUnarchiveFromDataTransformerName
        }
        return a
    }

    private static func makeToMany(name: String, destination: NSEntityDescription, inverseName: String?) -> NSRelationshipDescription {
        let r = NSRelationshipDescription()
        r.name = name
        r.destinationEntity = destination
        r.minCount = 0
        r.maxCount = 0 // to-many
        r.deleteRule = .cascadeDeleteRule
        return r
    }

    private static func makeToOne(name: String, destination: NSEntityDescription, inverseName: String?, optional: Bool) -> NSRelationshipDescription {
        let r = NSRelationshipDescription()
        r.name = name
        r.destinationEntity = destination
        r.minCount = optional ? 0 : 1
        r.maxCount = 1
        r.deleteRule = .cascadeDeleteRule
        return r
    }
}
