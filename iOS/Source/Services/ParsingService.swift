import Foundation

struct ParsedRecipe {
    var title: String?
    var imageURL: URL?
    var ingredients: [String]
    var steps: [String]
    var creatorName: String?
}

enum ParsingError: Error { case unsupported, network, invalid }

final class ParsingService {
    func parse(url: URL) async throws -> ParsedRecipe {
        // Placeholder: implement schema.org parsing + readability fallback.
        // For MVP scaffold, return an empty ParsedRecipe with best-effort title from URL.
        let title = url.host?.replacingOccurrences(of: "www.", with: "")
        return ParsedRecipe(title: title, imageURL: nil, ingredients: [], steps: [], creatorName: nil)
    }
}
