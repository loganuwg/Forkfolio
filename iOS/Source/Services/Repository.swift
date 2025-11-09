import Foundation
import Combine

protocol RepositoryProtocol: ObservableObject {
    var recipes: [Recipe] { get }
    func add(_ recipe: Recipe)
    func update(_ recipe: Recipe)
    func delete(_ recipe: Recipe)
    func search(query: String, tags: [String], creatorNames: [String], favoritesOnly: Bool) -> [Recipe]
}

final class InMemoryRepository: RepositoryProtocol {
    @Published private(set) var recipes: [Recipe] = []

    func add(_ recipe: Recipe) {
        recipes.append(recipe)
    }

    func update(_ recipe: Recipe) {
        if let idx = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[idx] = recipe
        }
    }

    func delete(_ recipe: Recipe) {
        recipes.removeAll { $0.id == recipe.id }
    }

    func search(query: String, tags: [String], creatorNames: [String], favoritesOnly: Bool) -> [Recipe] {
        recipes.filter { r in
            let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesQuery = q.isEmpty || r.title.lowercased().contains(q) || r.notes?.lowercased().contains(q) == true || r.ingredients.contains { $0.text.lowercased().contains(q) } || r.steps.contains { $0.text.lowercased().contains(q) } || (r.creator?.name.lowercased().contains(q) ?? false)
            let matchesTags = tags.isEmpty || !Set(tags.map { $0.lowercased() }).isDisjoint(with: r.tags.map { $0.lowercased() })
            let matchesCreator = creatorNames.isEmpty || (r.creator.map { creatorNames.map { $0.lowercased() }.contains($0.name.lowercased()) } ?? false)
            let matchesFav = !favoritesOnly || r.favorite
            return matchesQuery && matchesTags && matchesCreator && matchesFav
        }
    }
}
