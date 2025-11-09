import Foundation

struct Recipe: Identifiable, Hashable {
    let id: UUID
    var title: String
    var sourceURL: URL?
    var creator: Creator?
    var imageData: Data?
    var tags: [String]
    var favorite: Bool
    var rating: Int?
    var prepMinutes: Int?
    var cookMinutes: Int?
    var servings: Int?
    var notes: String?
    var ingredients: [Ingredient]
    var steps: [Step]
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        title: String,
        sourceURL: URL? = nil,
        creator: Creator? = nil,
        imageData: Data? = nil,
        tags: [String] = [],
        favorite: Bool = false,
        rating: Int? = nil,
        prepMinutes: Int? = nil,
        cookMinutes: Int? = nil,
        servings: Int? = nil,
        notes: String? = nil,
        ingredients: [Ingredient] = [],
        steps: [Step] = [],
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.sourceURL = sourceURL
        self.creator = creator
        self.imageData = imageData
        self.tags = tags
        self.favorite = favorite
        self.rating = rating
        self.prepMinutes = prepMinutes
        self.cookMinutes = cookMinutes
        self.servings = servings
        self.notes = notes
        self.ingredients = ingredients
        self.steps = steps
        self.dateAdded = dateAdded
    }
}

struct Ingredient: Identifiable, Hashable {
    let id: UUID
    var text: String
    var quantity: String?
    var unit: String?

    init(id: UUID = UUID(), text: String, quantity: String? = nil, unit: String? = nil) {
        self.id = id
        self.text = text
        self.quantity = quantity
        self.unit = unit
    }
}

struct Step: Identifiable, Hashable {
    let id: UUID
    var order: Int
    var text: String

    init(id: UUID = UUID(), order: Int, text: String) {
        self.id = id
        self.order = order
        self.text = text
    }
}

struct Creator: Identifiable, Hashable {
    let id: UUID
    var name: String
    var platform: String
    var profileURL: URL?

    init(id: UUID = UUID(), name: String, platform: String, profileURL: URL? = nil) {
        self.id = id
        self.name = name
        self.platform = platform
        self.profileURL = profileURL
    }
}
