import Foundation

final class RecipeEditorViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var sourceURLString: String = ""
    @Published var creatorName: String = ""
    @Published var creatorPlatform: String = "web"
    @Published var tagsText: String = ""
    @Published var favorite: Bool = false
    @Published var rating: Int = 0
    @Published var prepMinutes: Int?
    @Published var cookMinutes: Int?
    @Published var servings: Int?
    @Published var notes: String = ""
    @Published var ingredients: [Ingredient] = []
    @Published var steps: [Step] = []

    private var repository: RepositoryProtocol?
    private let parsing: ParsingService

    init(repository: RepositoryProtocol? = nil, parsing: ParsingService) {
        self.repository = repository
        self.parsing = parsing
    }

    func pasteURL() async {
        guard let url = URL(string: sourceURLString) else { return }
        do {
            let parsed = try await parsing.parse(url: url)
            if let t = parsed.title, title.isEmpty { title = t }
            if ingredients.isEmpty { ingredients = parsed.ingredients.map { Ingredient(text: $0) } }
            if steps.isEmpty { steps = parsed.steps.enumerated().map { Step(order: $0.offset + 1, text: $0.element) } }
            if creatorName.isEmpty, let c = parsed.creatorName { creatorName = c }
        } catch {
            // ignore for MVP scaffold
        }
    }

    func save() {
        guard let repository else { return }
        let url = URL(string: sourceURLString)
        let creator = creatorName.isEmpty ? nil : Creator(name: creatorName, platform: creatorPlatform)
        let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let recipe = Recipe(title: title.isEmpty ? "Untitled" : title,
                            sourceURL: url,
                            creator: creator,
                            tags: tags,
                            favorite: favorite,
                            rating: rating == 0 ? nil : rating,
                            prepMinutes: prepMinutes,
                            cookMinutes: cookMinutes,
                            servings: servings,
                            notes: notes.isEmpty ? nil : notes,
                            ingredients: ingredients,
                            steps: steps)
        repository.add(recipe)
    }

    func setRepository(_ repository: RepositoryProtocol) {
        self.repository = repository
    }
}
