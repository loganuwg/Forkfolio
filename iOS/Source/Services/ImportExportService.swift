import Foundation

final class ImportService {
    func importJSON(data: Data) throws -> [Recipe] {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let arr = json as? [[String: Any]] else { return [] }
        return arr.compactMap { dict in
            let title = (dict["title"] as? String) ?? "Untitled"
            let url = (dict["sourceURL"] as? String).flatMap(URL.init(string:))
            let creatorDict = dict["creator"] as? [String: Any]
            let creator = creatorDict.flatMap { d -> Creator? in
                let name = d["name"] as? String ?? ""
                let platform = d["platform"] as? String ?? "web"
                let profileURL = (d["profileURL"] as? String).flatMap(URL.init(string:))
                return Creator(name: name, platform: platform, profileURL: profileURL)
            }
            let tags = dict["tags"] as? [String] ?? []
            let rating = dict["rating"] as? Int
            let prep = dict["prepMinutes"] as? Int
            let cook = dict["cookMinutes"] as? Int
            let servings = dict["servings"] as? Int
            let notes = dict["notes"] as? String
            let ingredients = (dict["ingredients"] as? [String] ?? []).map { Ingredient(text: $0) }
            let steps = (dict["steps"] as? [String] ?? []).enumerated().map { Step(order: $0.offset + 1, text: $0.element) }
            return Recipe(title: title, sourceURL: url, creator: creator, tags: tags, favorite: false, rating: rating, prepMinutes: prep, cookMinutes: cook, servings: servings, notes: notes, ingredients: ingredients, steps: steps)
        }
    }

    func importCSV(data: Data) throws -> [Recipe] {
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else { return [] }
        let rows = parseCSV(text: text)
        guard let header = rows.first, rows.count > 1 else { return [] }
        let index = { (key: String) -> Int? in header.firstIndex { $0.caseInsensitiveCompare(key) == .orderedSame } }
        var results: [Recipe] = []
        for row in rows.dropFirst() {
            func val(_ key: String) -> String? {
                guard let i = index(key), i < row.count else { return nil }
                let v = row[i].trimmingCharacters(in: .whitespacesAndNewlines)
                return v.isEmpty ? nil : v
            }
            let title = val("title") ?? "Untitled"
            let url = val("sourceURL").flatMap(URL.init(string:))
            let creatorName = val("creatorName")
            let platform = val("platform") ?? "web"
            let profileURL = val("profileURL").flatMap(URL.init(string:))
            let creator = creatorName.map { Creator(name: $0, platform: platform, profileURL: profileURL) }
            let tags = val("tags").map { $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } } ?? []
            let rating = val("rating").flatMap { Int($0) }
            let prep = val("prepMinutes").flatMap { Int($0) }
            let cook = val("cookMinutes").flatMap { Int($0) }
            let servings = val("servings").flatMap { Int($0) }
            let notes = val("notes")
            let ingredientsArr = val("ingredients").map { $0.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) } } ?? []
            let stepsArr = val("steps").map { $0.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) } } ?? []
            let ingredients = ingredientsArr.map { Ingredient(text: $0) }
            let steps = stepsArr.enumerated().map { Step(order: $0.offset + 1, text: $0.element) }
            results.append(Recipe(title: title, sourceURL: url, creator: creator, tags: tags, favorite: false, rating: rating, prepMinutes: prep, cookMinutes: cook, servings: servings, notes: notes, ingredients: ingredients, steps: steps))
        }
        return results
    }

    private func parseCSV(text: String) -> [[String]] {
        var rows: [[String]] = []
        var current: [String] = []
        var field = ""
        var inQuotes = false
        var chars = Array(text)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c == "\"" {
                if inQuotes, i + 1 < chars.count, chars[i+1] == "\"" { // escaped quote
                    field.append("\"")
                    i += 1
                } else {
                    inQuotes.toggle()
                }
            } else if c == "," && !inQuotes {
                current.append(field)
                field = ""
            } else if (c == "\n" || c == "\r") && !inQuotes {
                // end of row
                if !(c == "\r" && i + 1 < chars.count && chars[i+1] == "\n") {
                    current.append(field)
                    rows.append(current)
                    current = []
                    field = ""
                }
            } else {
                field.append(c)
            }
            i += 1
        }
        // flush last
        if !inQuotes {
            current.append(field)
            if !current.isEmpty { rows.append(current) }
        }
        // normalize row lengths to header count
        if let headerCount = rows.first?.count {
            rows = rows.map { row in
                if row.count < headerCount { return row + Array(repeating: "", count: headerCount - row.count) }
                else if row.count > headerCount { return Array(row.prefix(headerCount)) }
                else { return row }
            }
        }
        return rows
    }
}

final class ExportService {
    func toText(_ recipe: Recipe) -> String {
        var lines: [String] = []
        lines.append(recipe.title)
        if let url = recipe.sourceURL { lines.append("Source: \(url.absoluteString)") }
        if let c = recipe.creator { lines.append("Creator: \(c.name) (\(c.platform))") }
        if !recipe.tags.isEmpty { lines.append("Tags: \(recipe.tags.joined(separator: ", "))") }
        if let s = recipe.servings { lines.append("Servings: \(s)") }
        if let p = recipe.prepMinutes { lines.append("Prep: \(p) min") }
        if let c = recipe.cookMinutes { lines.append("Cook: \(c) min") }
        if let r = recipe.rating { lines.append("Rating: \(r)/5") }
        if let n = recipe.notes, !n.isEmpty { lines.append("Notes: \(n)") }
        lines.append("\nIngredients:")
        for ing in recipe.ingredients { lines.append("- \(ing.text)") }
        lines.append("\nSteps:")
        for step in recipe.steps.sorted(by: { $0.order < $1.order }) { lines.append("\(step.order). \(step.text)") }
        return lines.joined(separator: "\n")
    }

    func toMarkdown(_ recipe: Recipe) -> String {
        var md: [String] = []
        md.append("# \(recipe.title)")
        if let url = recipe.sourceURL { md.append("Source: [link](\(url.absoluteString))") }
        if let c = recipe.creator { md.append("Creator: **\(c.name)** _(\(c.platform))_") }
        if !recipe.tags.isEmpty { md.append("Tags: \(recipe.tags.map { "`\($0)`" }.joined(separator: " "))") }
        var meta: [String] = []
        if let s = recipe.servings { meta.append("Servings: \(s)") }
        if let p = recipe.prepMinutes { meta.append("Prep: \(p) min") }
        if let c = recipe.cookMinutes { meta.append("Cook: \(c) min") }
        if let r = recipe.rating { meta.append("Rating: \(r)/5") }
        if !meta.isEmpty { md.append(meta.joined(separator: " • ")) }
        if let n = recipe.notes, !n.isEmpty { md.append("\n> \(n)") }
        md.append("\n## Ingredients")
        for ing in recipe.ingredients { md.append("- \(ing.text)") }
        md.append("\n## Steps")
        for step in recipe.steps.sorted(by: { $0.order < $1.order }) { md.append("\(step.order). \(step.text)") }
        return md.joined(separator: "\n")
    }
}
