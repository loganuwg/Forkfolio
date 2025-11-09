import Foundation
import Combine

final class LibraryViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var selectedTags: [String] = []
    @Published var selectedCreators: [String] = []
    @Published var favoritesOnly: Bool = false

    @Published private(set) var results: [Recipe] = []

    private var cancellables: Set<AnyCancellable> = []
    private var repository: RepositoryProtocol?

    init(repository: RepositoryProtocol? = nil) {
        self.repository = repository
        if let repository {
            results = repository.recipes
        }
    }

    func search() {
        guard let repository else { return }
        results = repository.search(query: query, tags: selectedTags, creatorNames: selectedCreators, favoritesOnly: favoritesOnly)
    }

    func setRepository(_ repository: RepositoryProtocol) {
        self.repository = repository
        self.results = repository.recipes
    }
}
