import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(recipe.title).font(.largeTitle).bold()
                if let url = recipe.sourceURL { Link("Source", destination: url) }
                if let c = recipe.creator { Text("By \(c.name) (") + Text(c.platform).italic() + Text(")") }
                if !recipe.tags.isEmpty { Text(recipe.tags.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary) }
                if let s = recipe.servings { Text("Servings: \(s)") }
                HStack(spacing: 16) {
                    if let p = recipe.prepMinutes { Text("Prep: \(p)m") }
                    if let c = recipe.cookMinutes { Text("Cook: \(c)m") }
                    if let r = recipe.rating { Text("Rating: \(r)/5") }
                }
                if let n = recipe.notes { Text(n).padding(.vertical, 4) }
                Text("Ingredients").font(.title2).bold().padding(.top, 8)
                ForEach(recipe.ingredients) { ing in Text("• \(ing.text)") }
                Text("Steps").font(.title2).bold().padding(.top, 8)
                ForEach(recipe.steps.sorted(by: { $0.order < $1.order })) { step in Text("\(step.order). \(step.text)") }
            }
            .padding()
        }
    }
}

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetailView(recipe: Recipe(title: "Sample"))
    }
}
