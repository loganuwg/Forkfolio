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
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode) else {
            throw ParsingError.network
        }
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw ParsingError.invalid
        }

        // Try JSON-LD (Schema.org Recipe)
        if let fromLD = parseJSONLD(html: html, baseURL: url) {
            return fromLD
        }

        // Fallback: basic title from <title>
        let title = extractHTMLTitle(html) ?? url.host?.replacingOccurrences(of: "www.", with: "")
        return ParsedRecipe(title: title, imageURL: nil, ingredients: [], steps: [], creatorName: nil)
    }

    private func parseJSONLD(html: String, baseURL: URL) -> ParsedRecipe? {
        // Find all <script type="application/ld+json"> blocks
        let pattern = "<script[^>]*type=\\\"application/ld\+json\\\"[^>]*>([\\s\\S]*?)</script>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(location: 0, length: (html as NSString).length)
        let matches = regex.matches(in: html, options: [], range: range)
        for match in matches {
            guard match.numberOfRanges >= 2 else { continue }
            let jsonRange = match.range(at: 1)
            guard let swiftRange = Range(jsonRange, in: html) else { continue }
            let jsonString = String(html[swiftRange])
            if let parsed = parseLDJSONBlock(jsonString: jsonString, baseURL: baseURL) {
                return parsed
            }
        }
        return nil
    }

    private func parseLDJSONBlock(jsonString: String, baseURL: URL) -> ParsedRecipe? {
        // Some sites include multiple objects or arrays; try to decode flexibly
        func toData(_ s: String) -> Data? { s.data(using: .utf8) }
        guard let data = toData(jsonString) else { return nil }
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            // Normalize to array of dicts
            let dicts: [[String: Any]]
            if let d = obj as? [String: Any] {
                dicts = [d]
            } else if let arr = obj as? [[String: Any]] {
                dicts = arr
            } else {
                return nil
            }

            // Find Recipe type
            for d in dicts {
                if let recipe = extractRecipeDict(d) ?? (d["@graph"] as? [[String: Any]]).flatMap({ graph in graph.compactMap(extractRecipeDict).first }) {
                    return toParsedRecipe(from: recipe, baseURL: baseURL)
                }
            }
        } catch {
            return nil
        }
        return nil
    }

    private func extractRecipeDict(_ dict: [String: Any]) -> [String: Any]? {
        func matchesRecipeType(_ val: Any?) -> Bool {
            if let s = val as? String { return s.lowercased().contains("recipe") }
            if let arr = val as? [Any] { return arr.contains { ($0 as? String)?.lowercased().contains("recipe") == true } }
            return false
        }
        if matchesRecipeType(dict["@type"]) { return dict }
        return nil
    }

    private func toParsedRecipe(from dict: [String: Any], baseURL: URL) -> ParsedRecipe {
        // Title
        let title = (dict["name"] as? String) ?? (dict["headline"] as? String)
        // Image can be string or array or object
        var imageURL: URL? = nil
        if let s = dict["image"] as? String, let u = URL(string: s, relativeTo: baseURL) { imageURL = u }
        else if let arr = dict["image"] as? [Any] {
            if let s = arr.first as? String, let u = URL(string: s, relativeTo: baseURL) { imageURL = u }
            else if let o = arr.first as? [String: Any], let s = o["url"] as? String, let u = URL(string: s, relativeTo: baseURL) { imageURL = u }
        } else if let o = dict["image"] as? [String: Any], let s = o["url"] as? String, let u = URL(string: s, relativeTo: baseURL) { imageURL = u }

        // Ingredients
        let ingredients: [String]
        if let arr = dict["recipeIngredient"] as? [String] { ingredients = arr }
        else if let arr = dict["ingredients"] as? [String] { ingredients = arr }
        else { ingredients = [] }

        // Instructions can be array of strings or array of HowToStep objects or a string
        var steps: [String] = []
        if let arr = dict["recipeInstructions"] as? [Any] {
            for el in arr {
                if let s = el as? String { steps.append(s) }
                else if let o = el as? [String: Any] {
                    if let s = o["text"] as? String { steps.append(s) }
                    else if let s = o["name"] as? String { steps.append(s) }
                }
            }
        } else if let s = dict["recipeInstructions"] as? String {
            steps = s.components(separatedBy: /\r?\n|\./).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }

        // Creator/author
        var creatorName: String? = nil
        if let author = dict["author"] as? [String: Any] { creatorName = author["name"] as? String }
        else if let authors = dict["author"] as? [[String: Any]], let a = authors.first { creatorName = a["name"] as? String }
        else if let publisher = dict["publisher"] as? [String: Any] { creatorName = publisher["name"] as? String }

        return ParsedRecipe(title: title, imageURL: imageURL, ingredients: ingredients, steps: steps, creatorName: creatorName)
    }

    private func extractHTMLTitle(_ html: String) -> String? {
        let pattern = "<title[^>]*>([\\s\\S]*?)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        guard let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: (html as NSString).length)) else { return nil }
        guard match.numberOfRanges >= 2, let range = Range(match.range(at: 1), in: html) else { return nil }
        let raw = String(html[range])
        return raw.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
